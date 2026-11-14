-- HU-04 / #5. Invitations expose only a minimal family/target snapshot.
create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  family_name text not null,
  target_user_id uuid not null references public.profiles(user_id) on delete restrict,
  target_public_id text not null,
  target_name text not null,
  invited_by uuid not null references public.profiles(user_id) on delete restrict,
  status text not null default 'pending' check(status in ('pending','accepted','rejected','revoked','expired')),
  expires_at timestamptz not null default now()+interval '7 days',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index invitations_pending_idx on public.invitations(family_id,target_user_id) where status='pending';
create index invitations_target_idx on public.invitations(target_user_id,created_at);
create index invitations_family_idx on public.invitations(family_id,created_at);
create index invitations_inviter_idx on public.invitations(invited_by);
create table private.lookup_rate_limits (
  actor_id uuid primary key references auth.users(id) on delete cascade,
  window_start timestamptz not null,
  requests integer not null check(requests>0)
);
alter table private.lookup_rate_limits enable row level security;
revoke all on private.lookup_rate_limits from public,anon,authenticated;
create function private.limit_user_lookup() returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); total integer;
begin
  insert into private.lookup_rate_limits(actor_id,window_start,requests) values(actor,clock_timestamp(),1)
  on conflict(actor_id) do update set
    requests=case when lookup_rate_limits.window_start < clock_timestamp()-interval '1 minute' then 1 else lookup_rate_limits.requests+1 end,
    window_start=case when lookup_rate_limits.window_start < clock_timestamp()-interval '1 minute' then clock_timestamp() else lookup_rate_limits.window_start end
  returning requests into total;
  if total>10 then raise exception 'rate_limited'; end if;
end;
$$;
create function private.invitation_visible(p_family_id uuid,p_target_user_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select private.has_live_session() and exists(select 1 from public.families f where f.id=p_family_id and f.deleted_at is null)
    and (p_target_user_id=auth.uid() or private.is_family_admin(p_family_id));
$$;
alter table public.invitations enable row level security;
revoke all on public.invitations from public,anon,authenticated;
grant select on public.invitations to authenticated;
create policy invitations_read on public.invitations for select to authenticated using(private.invitation_visible(family_id,target_user_id));
create function private.lookup_family_user(p_family_id uuid,p_public_id text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
  perform private.require_actor();
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  perform private.limit_user_lookup();
  if p_public_id is null or lower(btrim(p_public_id)) !~ '^[0-9a-f]{32}$' then return null; end if;
  select jsonb_build_object('public_id',p.public_id,'full_name',p.full_name) into result from public.profiles p
    where p.public_id=lower(btrim(p_public_id)) and p.user_id<>auth.uid();
  return result;
end;
$$;
create function private.invite_member(p_family_id uuid,p_target_public_id text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); target public.profiles; body jsonb; result jsonb; fid_name text;
begin
  select name into fid_name from public.families where id=p_family_id for update;
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  body:=jsonb_build_object('family_id',p_family_id,'target_public_id',lower(btrim(p_target_public_id)));
  result:=private.begin_request('invite_member',p_request_id,body);
  if result is not null then return result; end if;
  perform private.limit_user_lookup();
  select * into target from public.profiles where public_id=lower(btrim(p_target_public_id));
  if not found or target.user_id=actor or exists(select 1 from public.memberships where family_id=p_family_id and user_id=target.user_id and active)
  then return jsonb_build_object('error','invitation_unavailable'); end if;
  update public.invitations set status='expired',updated_at=now() where family_id=p_family_id and target_user_id=target.user_id and status='pending' and expires_at<=now();
  if exists(select 1 from public.invitations where family_id=p_family_id and target_user_id=target.user_id and status='pending') then return jsonb_build_object('error','invitation_unavailable'); end if;
  insert into public.invitations(family_id,family_name,target_user_id,target_public_id,target_name,invited_by)
    values(p_family_id,fid_name,target.user_id,target.public_id,target.full_name,actor) returning to_jsonb(invitations.*) into result;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,p_family_id,'invite_member',(result->>'id')::uuid);
  return private.finish_request('invite_member',p_request_id,body,result);
end;
$$;
create function private.respond_invitation(p_invitation_id uuid,p_decision text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); fid uuid; i public.invitations; body jsonb; result jsonb;
begin
  select family_id into fid from public.invitations where id=p_invitation_id;
  if fid is null then raise exception 'invitation_unavailable'; end if;
  perform 1 from public.families where id=fid and deleted_at is null for update;
  if not found then raise exception 'invitation_unavailable'; end if;
  select * into i from public.invitations where id=p_invitation_id for update;
  if i.target_user_id<>actor then raise exception 'invitation_unavailable'; end if;
  if p_decision is null or p_decision not in ('accept','reject') then raise exception 'validation_error'; end if;
  body:=jsonb_build_object('invitation_id',p_invitation_id,'decision',p_decision);
  result:=private.begin_request('respond_invitation',p_request_id,body);
  if result is not null then return result; end if;
  if i.status<>'pending' or i.expires_at<=now() or not exists(
    select 1 from public.memberships where family_id=fid and user_id=i.invited_by and active and is_admin)
  then raise exception 'invitation_unavailable'; end if;
  if p_decision='accept' and not exists(select 1 from public.memberships where family_id=fid and user_id=actor and active) then
    insert into public.memberships(family_id,user_id,is_admin) values(fid,actor,false)
      on conflict(family_id,user_id) do update set active=true,is_admin=false,joined_at=now();
  end if;
  update public.invitations set status=case when p_decision='accept' then 'accepted' else 'rejected' end,updated_at=now() where id=p_invitation_id returning to_jsonb(invitations.*) into result;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,fid,'respond_invitation',p_invitation_id);
  return private.finish_request('respond_invitation',p_request_id,body,result);
end;
$$;
create function private.revoke_invitation(p_invitation_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor();fid uuid;
begin
  select family_id into fid from public.invitations where id=p_invitation_id;
  perform 1 from public.families where id=fid for update;
  if not private.is_family_admin(fid) then raise exception using message='forbidden',errcode='42501'; end if;
  update public.invitations set status='revoked',updated_at=now() where id=p_invitation_id and status='pending';
  if not found then raise exception 'invitation_unavailable'; end if;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,fid,'revoke_invitation',p_invitation_id);
end;
$$;
create function public.lookup_family_user(p_family_id uuid,p_public_id text) returns jsonb
language sql security invoker set search_path='' as $$ select private.lookup_family_user(p_family_id,p_public_id); $$;
create function public.invite_member(p_family_id uuid,p_target_public_id text,p_request_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.invite_member(p_family_id,p_target_public_id,p_request_id); $$;
create function public.respond_invitation(p_invitation_id uuid,p_decision text,p_request_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.respond_invitation(p_invitation_id,p_decision,p_request_id); $$;
create function public.revoke_invitation(p_invitation_id uuid) returns void
language sql security invoker set search_path='' as $$ select private.revoke_invitation(p_invitation_id); $$;
revoke all on function private.limit_user_lookup(),private.invitation_visible(uuid,uuid),private.lookup_family_user(uuid,text),private.invite_member(uuid,text,uuid),private.respond_invitation(uuid,text,uuid),private.revoke_invitation(uuid) from public,anon,authenticated;
revoke all on function public.lookup_family_user(uuid,text),public.invite_member(uuid,text,uuid),public.respond_invitation(uuid,text,uuid),public.revoke_invitation(uuid) from public,anon,authenticated;
grant execute on function private.invitation_visible(uuid,uuid),private.lookup_family_user(uuid,text),private.invite_member(uuid,text,uuid),private.respond_invitation(uuid,text,uuid),private.revoke_invitation(uuid) to authenticated;
grant execute on function public.lookup_family_user(uuid,text),public.invite_member(uuid,text,uuid),public.respond_invitation(uuid,text,uuid),public.revoke_invitation(uuid) to authenticated;
