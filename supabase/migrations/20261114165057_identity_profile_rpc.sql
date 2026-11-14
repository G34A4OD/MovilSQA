-- HU-02 / #3. Private implementations are definer because table DML is revoked.
-- Public API wrappers remain invoker; every implementation validates Auth.
create function private.begin_request(p_operation text,p_request_id uuid,p_body jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); old private.request_dedup;
begin
  if p_request_id is null then raise exception 'validation_error'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(actor::text||p_operation||p_request_id::text,0));
  select * into old from private.request_dedup where actor_id=actor and operation=p_operation and request_id=p_request_id;
  if found and old.created_at > now()-interval '24 hours' then
    if old.request_body <> p_body then raise exception 'request_conflict'; end if;
    return old.result;
  end if;
  delete from private.request_dedup where actor_id=actor and operation=p_operation and request_id=p_request_id;
  return null;
end;
$$;
create function private.finish_request(p_operation text,p_request_id uuid,p_body jsonb,p_result jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  insert into private.request_dedup(actor_id,operation,request_id,request_body,result)
    values(private.require_actor(),p_operation,p_request_id,p_body,p_result);
  return p_result;
end;
$$;
create function private.profile_result(p_user_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select to_jsonb(p)||(to_jsonb(s)-'user_id') from public.profiles p
  join public.private_profiles s using(user_id) where p.user_id=p_user_id;
$$;
create function private.validate_profile(p_full_name text,p_blood_type text,p_identity_card text,p_birth_date date,p_address text) returns void
language plpgsql stable set search_path = '' as $$
begin
  if p_full_name is null or char_length(btrim(p_full_name)) not between 2 and 120
    or p_identity_card is null or char_length(btrim(p_identity_card)) not between 3 and 30
    or p_address is null or char_length(btrim(p_address)) not between 3 and 250
    or p_birth_date is null or p_birth_date < date '1900-01-01' or p_birth_date > current_date
    or (p_blood_type is not null and p_blood_type not in ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
  then raise exception 'validation_error'; end if;
end;
$$;
create function private.complete_profile(p_full_name text,p_blood_type text,p_identity_card text,p_birth_date date,p_address text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor();
begin
  perform private.validate_profile(p_full_name,p_blood_type,p_identity_card,p_birth_date,p_address);
  -- Serialize first submission. Existing profiles cannot be overwritten without version.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(actor::text||'profile',0));
  if exists(select 1 from public.profiles where user_id=actor) then raise exception 'profile_exists'; end if;
  insert into public.profiles(user_id,full_name) values(actor,btrim(p_full_name));
  insert into public.private_profiles(user_id,blood_type,identity_card,birth_date,address)
    values(actor,p_blood_type,btrim(p_identity_card),p_birth_date,btrim(p_address));
  return private.profile_result(actor);
end;
$$;
create function private.update_profile(p_full_name text,p_blood_type text,p_identity_card text,p_birth_date date,p_address text,p_expected_version integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor();
begin
  perform private.validate_profile(p_full_name,p_blood_type,p_identity_card,p_birth_date,p_address);
  perform 1 from public.profiles where user_id=actor for update;
  if not found then raise exception 'profile_unavailable'; end if;
  if p_expected_version is null or p_expected_version <> (select version from public.profiles where user_id=actor) then raise exception 'version_conflict'; end if;
  update public.profiles set full_name=btrim(p_full_name), version=version+1,updated_at=now() where user_id=actor;
  update public.private_profiles set blood_type=p_blood_type,identity_card=btrim(p_identity_card),birth_date=p_birth_date,address=btrim(p_address) where user_id=actor;
  return private.profile_result(actor);
end;
$$;
create function private.set_profile_share(p_family_id uuid,p_selected_fields text[],p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); body jsonb; cached jsonb; fields jsonb; result jsonb;
begin
  perform 1 from public.families where id=p_family_id for update;
  if not private.is_active_member(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  if p_selected_fields is null or cardinality(p_selected_fields)>4 or exists(
    select 1 from unnest(p_selected_fields) f where f is null or f not in ('blood_type','identity_card','birth_date','address'))
  then raise exception 'validation_error'; end if;
  body := jsonb_build_object('family_id',p_family_id,'fields',p_selected_fields);
  cached := private.begin_request('set_profile_share',p_request_id,body);
  if cached is not null then return cached; end if;
  select coalesce(jsonb_object_agg(e.key,e.value),'{}'::jsonb) into fields
    from jsonb_each(private.profile_result(actor)) e where e.key=any(p_selected_fields);
  insert into public.profile_shares(family_id,user_id,selected_fields) values(p_family_id,actor,fields)
    on conflict(family_id,user_id) do update set selected_fields=excluded.selected_fields,consented_at=now(),version=profile_shares.version+1;
  select to_jsonb(s) into result from public.profile_shares s where family_id=p_family_id and user_id=actor;
  insert into private.audit_events(actor_id,family_id,operation) values(actor,p_family_id,'set_profile_share');
  return private.finish_request('set_profile_share',p_request_id,body,result);
end;
$$;

create function public.complete_profile(p_full_name text,p_blood_type text,p_identity_card text,p_birth_date date,p_address text) returns jsonb
language sql security invoker set search_path = '' as $$ select private.complete_profile(p_full_name,p_blood_type,p_identity_card,p_birth_date,p_address); $$;
create function public.update_profile(p_full_name text,p_blood_type text,p_identity_card text,p_birth_date date,p_address text,p_expected_version integer) returns jsonb
language sql security invoker set search_path = '' as $$ select private.update_profile(p_full_name,p_blood_type,p_identity_card,p_birth_date,p_address,p_expected_version); $$;
create function public.set_profile_share(p_family_id uuid,p_selected_fields text[],p_request_id uuid) returns jsonb
language sql security invoker set search_path = '' as $$ select private.set_profile_share(p_family_id,p_selected_fields,p_request_id); $$;
revoke all on function public.complete_profile(text,text,text,date,text),public.update_profile(text,text,text,date,text,integer),public.set_profile_share(uuid,text[],uuid) from public,anon,authenticated;
revoke all on function private.complete_profile(text,text,text,date,text),private.update_profile(text,text,text,date,text,integer),private.set_profile_share(uuid,text[],uuid),private.begin_request(text,uuid,jsonb),private.finish_request(text,uuid,jsonb,jsonb),private.profile_result(uuid),private.validate_profile(text,text,text,date,text) from public,anon,authenticated;
grant execute on function public.complete_profile(text,text,text,date,text),public.update_profile(text,text,text,date,text,integer),public.set_profile_share(uuid,text[],uuid) to authenticated;
grant execute on function private.complete_profile(text,text,text,date,text),private.update_profile(text,text,text,date,text,integer),private.set_profile_share(uuid,text[],uuid) to authenticated;
