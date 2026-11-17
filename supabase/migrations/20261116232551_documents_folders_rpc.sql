-- HU-08 / #9. Folders belong to a family with exactly one human or pet owner.
-- owner_access_epoch is stamped from memberships; the client never chooses it.
-- delete_folder removes an empty folder and audits. Enqueueing cleanup_jobs
-- waits for Gerardo to accept operation='delete_folder' on the shared check.

create table public.folders (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null
    check (char_length(btrim(name)) between 1 and 100)
    check (btrim(name) !~ '[/\\]' and btrim(name) !~ '[[:cntrl:]]'),
  owner_user_id uuid,
  pet_id uuid,
  owner_access_epoch uuid,
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, id),
  check (
    (owner_user_id is not null and pet_id is null and owner_access_epoch is not null)
    or (owner_user_id is null and pet_id is not null and owner_access_epoch is null)
  ),
  foreign key (family_id, owner_user_id) references public.memberships(family_id, user_id),
  foreign key (family_id, pet_id) references public.pets(family_id, id)
);
create index folders_family_idx on public.folders(family_id);
create index folders_owner_idx on public.folders(family_id, owner_user_id) where owner_user_id is not null;
create index folders_pet_idx on public.folders(family_id, pet_id) where pet_id is not null;

create function private.folder_name_valid(p_name text) returns boolean
language sql immutable set search_path = '' as $$
  select p_name is not null
    and char_length(btrim(p_name)) between 1 and 100
    and btrim(p_name) !~ '[/\\]'
    and btrim(p_name) !~ '[[:cntrl:]]';
$$;

create function private.folder_readable(
  p_family_id uuid,
  p_owner_user_id uuid,
  p_owner_access_epoch uuid,
  p_pet_id uuid
) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.is_active_member(p_family_id)
    and (
      (
        p_owner_user_id is not null
        and exists (
          select 1 from public.memberships m
          where m.family_id = p_family_id
            and m.user_id = p_owner_user_id
            and m.active
            and m.access_epoch = p_owner_access_epoch
        )
      )
      or (
        p_pet_id is not null
        and exists (
          select 1 from public.pets p
          where p.family_id = p_family_id
            and p.id = p_pet_id
            and p.deleted_at is null
        )
      )
    );
$$;

create function private.folder_writable(
  p_family_id uuid,
  p_owner_user_id uuid,
  p_owner_access_epoch uuid,
  p_pet_id uuid
) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session()
    and private.is_active_member(p_family_id)
    and (
      private.is_family_admin(p_family_id)
      or (
        p_owner_user_id is not null
        and p_owner_user_id = auth.uid()
        and exists (
          select 1 from public.memberships m
          where m.family_id = p_family_id
            and m.user_id = p_owner_user_id
            and m.active
            and m.access_epoch = p_owner_access_epoch
        )
      )
    )
    and (
      p_pet_id is null
      or exists (
        select 1 from public.pets p
        where p.family_id = p_family_id
          and p.id = p_pet_id
          and p.deleted_at is null
      )
    );
$$;

create function private.folders_before_write() returns trigger
language plpgsql security definer set search_path = '' as $$
declare epoch uuid;
begin
  if not private.has_live_session() then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if tg_op = 'UPDATE' then
    if new.id is distinct from old.id
      or new.family_id is distinct from old.family_id
      or new.owner_user_id is distinct from old.owner_user_id
      or new.pet_id is distinct from old.pet_id
    then
      raise exception using message = 'forbidden', errcode = '42501';
    end if;
    -- Ignore any client-supplied epoch; keep the stamped generation.
    new.owner_access_epoch := old.owner_access_epoch;
    if new.version is distinct from old.version then
      raise exception 'version_conflict';
    end if;
    new.version := old.version + 1;
    new.updated_at := now();
  end if;
  if not private.folder_name_valid(new.name) then
    raise exception 'validation_error';
  end if;
  new.name := btrim(new.name);
  if new.owner_user_id is not null and new.pet_id is not null then
    raise exception 'validation_error';
  end if;
  if new.owner_user_id is null and new.pet_id is null then
    raise exception 'validation_error';
  end if;
  if tg_op = 'INSERT' then
    if new.owner_user_id is not null then
      if new.owner_user_id <> auth.uid() then
        raise exception using message = 'forbidden', errcode = '42501';
      end if;
      select m.access_epoch into epoch
        from public.memberships m
        where m.family_id = new.family_id
          and m.user_id = new.owner_user_id
          and m.active;
      if epoch is null then
        raise exception using message = 'forbidden', errcode = '42501';
      end if;
      new.pet_id := null;
      new.owner_access_epoch := epoch;
    else
      if not private.is_family_admin(new.family_id) then
        raise exception using message = 'forbidden', errcode = '42501';
      end if;
      if not exists (
        select 1 from public.pets p
        where p.id = new.pet_id
          and p.family_id = new.family_id
          and p.deleted_at is null
      ) then
        raise exception 'pet_unavailable';
      end if;
      new.owner_user_id := null;
      new.owner_access_epoch := null;
    end if;
    new.version := 1;
    new.created_at := now();
    new.updated_at := now();
  elsif new.pet_id is not null
    and not exists (
      select 1 from public.pets p
      where p.id = new.pet_id
        and p.family_id = new.family_id
        and p.deleted_at is null
    )
  then
    raise exception 'pet_unavailable';
  end if;
  return new;
end;
$$;

create trigger folders_before_write
  before insert or update on public.folders
  for each row execute function private.folders_before_write();

alter table public.folders enable row level security;
revoke all on public.folders from public, anon, authenticated;
grant select, insert, update on public.folders to authenticated;

create policy folders_read on public.folders for select to authenticated
using (
  private.folder_readable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

create policy folders_insert on public.folders for insert to authenticated
with check (
  private.is_active_member(family_id)
  and (
    (owner_user_id = auth.uid() and pet_id is null)
    or (owner_user_id is null and pet_id is not null and private.is_family_admin(family_id))
  )
);

create policy folders_update on public.folders for update to authenticated
using (
  private.folder_writable(family_id, owner_user_id, owner_access_epoch, pet_id)
)
with check (
  private.folder_writable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

create function private.delete_folder(p_folder_id uuid, p_expected_version integer) returns void
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor();
  old public.folders;
begin
  select * into old from public.folders where id = p_folder_id for update;
  if not found then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  perform 1 from public.families where id = old.family_id for update;
  if not private.folder_writable(
    old.family_id, old.owner_user_id, old.owner_access_epoch, old.pet_id
  ) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version <> old.version then
    raise exception 'version_conflict';
  end if;
  delete from public.folders where id = p_folder_id;
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, old.family_id, 'delete_folder', p_folder_id);
  -- cleanup_jobs.operation='delete_folder' requires Gerardo to widen the shared check.
end;
$$;

create function public.delete_folder(p_folder_id uuid, p_expected_version integer) returns void
language sql security invoker set search_path = '' as $$
  select private.delete_folder(p_folder_id, p_expected_version);
$$;

revoke all on function private.folder_name_valid(text),
  private.folder_readable(uuid, uuid, uuid, uuid),
  private.folder_writable(uuid, uuid, uuid, uuid),
  private.folders_before_write(),
  private.delete_folder(uuid, integer)
  from public, anon, authenticated;
revoke all on function public.delete_folder(uuid, integer)
  from public, anon, authenticated;
grant execute on function private.folder_readable(uuid, uuid, uuid, uuid),
  private.folder_writable(uuid, uuid, uuid, uuid),
  private.delete_folder(uuid, integer)
  to authenticated;
grant execute on function public.delete_folder(uuid, integer) to authenticated;
