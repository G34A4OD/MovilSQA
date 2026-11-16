-- HU-06 / #7. Explicit family roles; inverse labels are mapped by Flutter.
alter table public.families add column relationship_revision bigint not null default 0;
create table public.relationships (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  from_user_id uuid not null,
  to_user_id uuid not null,
  from_access_epoch uuid not null,
  to_access_epoch uuid not null,
  kind text not null check(kind in ('parent','grandparent','uncle','sibling','cousin','partner')),
  version integer not null default 1 check(version>0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key(family_id,from_user_id) references public.memberships(family_id,user_id) on delete cascade,
  foreign key(family_id,to_user_id) references public.memberships(family_id,user_id) on delete cascade,
  check(from_user_id<>to_user_id),
  check(kind not in ('sibling','cousin','partner') or from_user_id<to_user_id),
  unique(family_id,from_user_id,to_user_id,kind,from_access_epoch,to_access_epoch)
);
create index relationships_from_idx on public.relationships(family_id,from_user_id);
create index relationships_to_idx on public.relationships(family_id,to_user_id);
create function private.relationship_visible(p_family_id uuid,p_from uuid,p_from_epoch uuid,p_to uuid,p_to_epoch uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select private.is_active_member(p_family_id) and exists(
    select 1 from public.memberships a join public.memberships b on b.family_id=a.family_id
    where a.family_id=p_family_id and a.user_id=p_from and a.active and a.access_epoch=p_from_epoch
      and b.user_id=p_to and b.active and b.access_epoch=p_to_epoch
  );
$$;
alter table public.relationships enable row level security;
revoke all on public.relationships from public,anon,authenticated;
grant select on public.relationships to authenticated;
create policy relationships_read on public.relationships for select to authenticated
using(private.relationship_visible(family_id,from_user_id,from_access_epoch,to_user_id,to_access_epoch));
create function private.save_relationship(p_family_id uuid,p_relationship_id uuid,p_from_user_id uuid,p_to_user_id uuid,p_kind text,p_expected_version integer,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); a uuid:=p_from_user_id; b uuid:=p_to_user_id;
  ae uuid;be uuid;swap uuid;old public.relationships;body jsonb;result jsonb;
begin
  perform 1 from public.families where id=p_family_id for update;
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  if a is null or b is null or a=b or p_kind is null or p_kind not in ('parent','grandparent','uncle','sibling','cousin','partner') then raise exception 'invalid_relationship'; end if;
  if p_kind in ('sibling','cousin','partner') and a>b then swap:=a;a:=b;b:=swap;end if;
  select access_epoch into ae from public.memberships where family_id=p_family_id and user_id=a and active;
  select access_epoch into be from public.memberships where family_id=p_family_id and user_id=b and active;
  if ae is null or be is null then raise exception 'invalid_relationship'; end if;
  body:=jsonb_build_object('family_id',p_family_id,'id',p_relationship_id,'from',a,'to',b,'kind',p_kind,'version',p_expected_version);
  result:=private.begin_request('save_relationship',p_request_id,body);
  if result is not null then return result; end if;
  if p_relationship_id is not null then
    select * into old from public.relationships where id=p_relationship_id and family_id=p_family_id for update;
    if not found then raise exception 'invalid_relationship'; end if;
    if p_expected_version is null or old.version<>p_expected_version then raise exception 'version_conflict'; end if;
  end if;
  if exists(select 1 from public.relationships r where r.family_id=p_family_id and r.from_user_id=a and r.to_user_id=b and r.kind=p_kind and r.from_access_epoch=ae and r.to_access_epoch=be and r.id is distinct from p_relationship_id) then raise exception 'invalid_relationship'; end if;
  if p_kind in ('parent','grandparent') and exists(
    with recursive descendants(user_id) as (
      select b union select r.to_user_id from public.relationships r join descendants d on r.from_user_id=d.user_id
      join public.memberships m1 on m1.family_id=r.family_id and m1.user_id=r.from_user_id and m1.active and m1.access_epoch=r.from_access_epoch
      join public.memberships m2 on m2.family_id=r.family_id and m2.user_id=r.to_user_id and m2.active and m2.access_epoch=r.to_access_epoch
      where r.family_id=p_family_id and r.kind in ('parent','grandparent') and r.id is distinct from p_relationship_id
    ) select 1 from descendants where user_id=a
  ) then raise exception 'invalid_relationship'; end if;
  update public.families set relationship_revision=relationship_revision+1 where id=p_family_id;
  if p_relationship_id is null then
    insert into public.relationships(family_id,from_user_id,to_user_id,from_access_epoch,to_access_epoch,kind)
      values(p_family_id,a,b,ae,be,p_kind) returning to_jsonb(relationships.*) into result;
  else
    update public.relationships set from_user_id=a,to_user_id=b,from_access_epoch=ae,to_access_epoch=be,kind=p_kind,version=version+1,updated_at=now()
      where id=p_relationship_id returning to_jsonb(relationships.*) into result;
  end if;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,p_family_id,'save_relationship',(result->>'id')::uuid);
  return private.finish_request('save_relationship',p_request_id,body,result);
end;
$$;
create function private.delete_relationship(p_family_id uuid,p_relationship_id uuid,p_expected_version integer) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor();old public.relationships;
begin
  perform 1 from public.families where id=p_family_id for update;
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  select * into old from public.relationships where id=p_relationship_id and family_id=p_family_id for update;
  if not found then raise exception 'invalid_relationship'; end if;
  if p_expected_version is null or old.version<>p_expected_version then raise exception 'version_conflict'; end if;
  update public.families set relationship_revision=relationship_revision+1 where id=p_family_id;
  delete from public.relationships where id=p_relationship_id;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,p_family_id,'delete_relationship',p_relationship_id);
end;
$$;
create function public.save_relationship(p_family_id uuid,p_relationship_id uuid,p_from_user_id uuid,p_to_user_id uuid,p_kind text,p_expected_version integer,p_request_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.save_relationship(p_family_id,p_relationship_id,p_from_user_id,p_to_user_id,p_kind,p_expected_version,p_request_id); $$;
create function public.delete_relationship(p_family_id uuid,p_relationship_id uuid,p_expected_version integer) returns void
language sql security invoker set search_path='' as $$ select private.delete_relationship(p_family_id,p_relationship_id,p_expected_version); $$;
revoke all on function private.relationship_visible(uuid,uuid,uuid,uuid,uuid),private.save_relationship(uuid,uuid,uuid,uuid,text,integer,uuid),private.delete_relationship(uuid,uuid,integer) from public,anon,authenticated;
revoke all on function public.save_relationship(uuid,uuid,uuid,uuid,text,integer,uuid),public.delete_relationship(uuid,uuid,integer) from public,anon,authenticated;
grant execute on function private.relationship_visible(uuid,uuid,uuid,uuid,uuid),private.save_relationship(uuid,uuid,uuid,uuid,text,integer,uuid),private.delete_relationship(uuid,uuid,integer) to authenticated;
grant execute on function public.save_relationship(uuid,uuid,uuid,uuid,text,integer,uuid),public.delete_relationship(uuid,uuid,integer) to authenticated;
