-- HU-03 / #4. Logical deletion revokes access first; a trusted worker cleans
-- files and rows later, without exposing deleted data while it retries.
alter table public.families add column deleted_at timestamptz;
create table private.cleanup_jobs (
  id uuid primary key default gen_random_uuid(),
  operation text not null check (operation in ('delete_family','remove_member','delete_pet','delete_account')),
  family_id uuid,
  resource_id uuid not null,
  status text not null default 'pending' check (status in ('pending','running','done','error')),
  attempts integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(operation,resource_id,family_id)
);
alter table private.cleanup_jobs enable row level security;
revoke all on private.cleanup_jobs from public,anon,authenticated;
grant usage on schema private to service_role;
grant select,insert,update,delete on private.cleanup_jobs to service_role;
create index cleanup_jobs_pending_idx on private.cleanup_jobs(status,created_at);

create or replace function private.is_active_member(p_family_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from public.memberships m join public.families f on f.id=m.family_id
    where m.family_id=p_family_id and m.user_id=auth.uid() and m.active and f.deleted_at is null
  );
$$;
create or replace function private.is_family_admin(p_family_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from public.memberships m join public.families f on f.id=m.family_id
    where m.family_id=p_family_id and m.user_id=auth.uid() and m.active and m.is_admin and f.deleted_at is null
  );
$$;
create or replace function private.shares_family_with(p_user_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from public.memberships mine join public.memberships theirs on theirs.family_id=mine.family_id
    join public.families f on f.id=mine.family_id
    where mine.user_id=auth.uid() and mine.active and theirs.user_id=p_user_id and theirs.active and f.deleted_at is null
  );
$$;
create function private.has_recent_auth() returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from jsonb_array_elements(coalesce(auth.jwt()->'amr','[]'::jsonb)) a
    where a->>'method'='password' and (a->>'timestamp')::bigint >= extract(epoch from now()-interval '10 minutes')
  );
$$;
create function private.create_family(p_name text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); body jsonb; result jsonb; fid uuid;
begin
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100 or
    not exists(select 1 from public.private_profiles where user_id=actor) then raise exception 'validation_error'; end if;
  body := jsonb_build_object('name',btrim(p_name));
  result := private.begin_request('create_family',p_request_id,body);
  if result is not null then
    if not private.is_active_member((result->>'id')::uuid) then raise exception using message='forbidden',errcode='42501'; end if;
    return result;
  end if;
  insert into public.families(name,created_by) values(btrim(p_name),actor) returning id into fid;
  insert into public.memberships(family_id,user_id,is_admin) values(fid,actor,true);
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,fid,'create_family',fid);
  select to_jsonb(f) into result from public.families f where id=fid;
  return private.finish_request('create_family',p_request_id,body,result);
end;
$$;
create function private.update_family(p_family_id uuid,p_name text,p_expected_version integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); current_version integer; result jsonb;
begin
  select version into current_version from public.families where id=p_family_id for update;
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  if p_expected_version is null or p_expected_version<>current_version then raise exception 'version_conflict'; end if;
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100 then raise exception 'validation_error'; end if;
  update public.families set name=btrim(p_name),version=version+1,updated_at=now() where id=p_family_id returning to_jsonb(families.*) into result;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,p_family_id,'update_family',p_family_id);
  return result;
end;
$$;
create function private.delete_family(p_family_id uuid,p_expected_version integer,p_confirmation text) returns void
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); f public.families;
begin
  select * into f from public.families where id=p_family_id for update;
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  if p_expected_version is null or p_expected_version<>f.version then raise exception 'version_conflict'; end if;
  if p_confirmation is null or p_confirmation<>f.name then raise exception 'validation_error'; end if;
  if not private.has_recent_auth() then raise exception 'reauth_required'; end if;
  update public.families set deleted_at=now(),version=version+1,updated_at=now() where id=p_family_id;
  insert into private.cleanup_jobs(operation,family_id,resource_id) values('delete_family',p_family_id,p_family_id) on conflict do nothing;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,p_family_id,'delete_family',p_family_id);
end;
$$;
create function public.create_family(p_name text,p_request_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.create_family(p_name,p_request_id); $$;
create function public.update_family(p_family_id uuid,p_name text,p_expected_version integer) returns jsonb
language sql security invoker set search_path='' as $$ select private.update_family(p_family_id,p_name,p_expected_version); $$;
create function public.delete_family(p_family_id uuid,p_expected_version integer,p_confirmation text) returns void
language sql security invoker set search_path='' as $$ select private.delete_family(p_family_id,p_expected_version,p_confirmation); $$;
revoke all on function private.has_recent_auth(),private.create_family(text,uuid),private.update_family(uuid,text,integer),private.delete_family(uuid,integer,text) from public,anon,authenticated;
revoke all on function public.create_family(text,uuid),public.update_family(uuid,text,integer),public.delete_family(uuid,integer,text) from public,anon,authenticated;
grant execute on function private.create_family(text,uuid),private.update_family(uuid,text,integer),private.delete_family(uuid,integer,text) to authenticated;
grant execute on function public.create_family(text,uuid),public.update_family(uuid,text,integer),public.delete_family(uuid,integer,text) to authenticated;
