-- HU-05 / #6. All removals/demotions serialize on the same family row.
alter table public.families add column membership_revision bigint not null default 0;
alter table public.memberships add column access_epoch uuid not null default gen_random_uuid();
alter table private.cleanup_jobs add column metadata jsonb not null default '{}'::jsonb;

create function private.change_membership(p_family_id uuid,p_target_user_id uuid,p_is_admin boolean,p_remove boolean) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); target public.memberships; result jsonb;
begin
  perform 1 from public.families where id=p_family_id for update;
  if not private.is_active_member(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  if p_remove is null or (not p_remove and p_is_admin is null) then raise exception 'validation_error'; end if;
  if (p_remove and actor<>p_target_user_id and not private.is_family_admin(p_family_id))
    or (not p_remove and not private.is_family_admin(p_family_id))
  then raise exception using message='forbidden',errcode='42501'; end if;
  select * into target from public.memberships where family_id=p_family_id and user_id=p_target_user_id and active for update;
  if not found then raise exception using message='forbidden',errcode='42501'; end if;
  if target.is_admin and (p_remove or not p_is_admin) and
    (select count(*) from public.memberships where family_id=p_family_id and active and is_admin)<2
  then raise exception 'last_admin'; end if;
  -- Touch the locked row too: REPEATABLE READ must serialize/fail rather than
  -- count a stale snapshot after waiting on an unchanged SELECT FOR UPDATE row.
  update public.families set membership_revision=membership_revision+1 where id=p_family_id;
  if p_remove then
    update public.memberships set active=false,is_admin=false,access_epoch=gen_random_uuid()
      where family_id=p_family_id and user_id=p_target_user_id returning to_jsonb(memberships.*) into result;
    delete from public.profile_shares where family_id=p_family_id and user_id=p_target_user_id;
    update public.invitations set status='revoked',updated_at=now() where family_id=p_family_id and status='pending' and (target_user_id=p_target_user_id or invited_by=p_target_user_id);
    insert into private.cleanup_jobs(operation,family_id,resource_id,metadata)
      values('remove_member',p_family_id,p_target_user_id,jsonb_build_object('old_access_epoch',target.access_epoch))
      on conflict(operation,resource_id,family_id) do update set status='pending',attempts=0,created_at=now(),updated_at=now(),metadata=excluded.metadata;
  else
    update public.memberships set is_admin=p_is_admin where family_id=p_family_id and user_id=p_target_user_id returning to_jsonb(memberships.*) into result;
    if not p_is_admin then
      update public.invitations set status='revoked',updated_at=now() where family_id=p_family_id and invited_by=p_target_user_id and status='pending';
    end if;
  end if;
  insert into private.audit_events(actor_id,family_id,operation,resource_id)
    values(actor,p_family_id,case when p_remove then 'remove_member' else 'set_member_admin' end,p_target_user_id);
  return result;
end;
$$;
create function private.set_member_admin(p_family_id uuid,p_target_user_id uuid,p_is_admin boolean) returns jsonb
language sql security definer set search_path='' as $$ select private.change_membership(p_family_id,p_target_user_id,p_is_admin,false); $$;
create function private.leave_family(p_family_id uuid) returns jsonb
language sql security definer set search_path='' as $$ select private.change_membership(p_family_id,private.require_actor(),null,true); $$;
create function private.remove_member(p_family_id uuid,p_target_user_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  return private.change_membership(p_family_id,p_target_user_id,null,true);
end;
$$;
create function public.set_member_admin(p_family_id uuid,p_target_user_id uuid,p_is_admin boolean) returns jsonb
language sql security invoker set search_path='' as $$ select private.set_member_admin(p_family_id,p_target_user_id,p_is_admin); $$;
create function public.leave_family(p_family_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.leave_family(p_family_id); $$;
create function public.remove_member(p_family_id uuid,p_target_user_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.remove_member(p_family_id,p_target_user_id); $$;
revoke all on function private.change_membership(uuid,uuid,boolean,boolean),private.set_member_admin(uuid,uuid,boolean),private.leave_family(uuid),private.remove_member(uuid,uuid) from public,anon,authenticated;
revoke all on function public.set_member_admin(uuid,uuid,boolean),public.leave_family(uuid),public.remove_member(uuid,uuid) from public,anon,authenticated;
grant execute on function private.set_member_admin(uuid,uuid,boolean),private.leave_family(uuid),private.remove_member(uuid,uuid) to authenticated;
grant execute on function public.set_member_admin(uuid,uuid,boolean),public.leave_family(uuid),public.remove_member(uuid,uuid) to authenticated;
