-- HU-08 / #9. Soft-delete folders so an ID with pending cleanup cannot be reused.
-- Keeps delete_folder(p_folder_id, p_expected_version); physical purge stays out of scope.

alter table public.folders add column deleted_at timestamptz;
create index folders_live_idx on public.folders(family_id) where deleted_at is null;

drop policy if exists folders_read on public.folders;
create policy folders_read on public.folders for select to authenticated
using (
  deleted_at is null
  and private.folder_readable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

drop policy if exists folders_update on public.folders;
create policy folders_update on public.folders for update to authenticated
using (
  deleted_at is null
  and private.folder_writable(family_id, owner_user_id, owner_access_epoch, pet_id)
)
with check (
  deleted_at is null
  and private.folder_writable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

create or replace function private.folders_before_write() returns trigger
language plpgsql security definer set search_path = '' as $$
declare epoch uuid;
begin
  if not private.has_live_session() then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if tg_op = 'UPDATE' then
    if new.deleted_at is distinct from old.deleted_at then
      if current_setting('nido.soft_delete_folder', true) is distinct from '1' then
        raise exception using message = 'forbidden', errcode = '42501';
      end if;
      if old.deleted_at is not null or new.deleted_at is null then
        raise exception using message = 'forbidden', errcode = '42501';
      end if;
      new.family_id := old.family_id;
      new.owner_user_id := old.owner_user_id;
      new.pet_id := old.pet_id;
      new.owner_access_epoch := old.owner_access_epoch;
      new.name := old.name;
      new.version := old.version + 1;
      new.updated_at := now();
      return new;
    end if;
    if new.id is distinct from old.id
      or new.family_id is distinct from old.family_id
      or new.owner_user_id is distinct from old.owner_user_id
      or new.pet_id is distinct from old.pet_id
      or old.deleted_at is not null
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
    new.deleted_at := null;
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
    new.deleted_at := null;
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

create or replace function private.delete_folder(
  p_folder_id uuid,
  p_expected_version integer
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  old public.folders;
begin
  select * into old
    from public.folders
    where id = p_folder_id
      and deleted_at is null
    for update;
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
  perform set_config('nido.soft_delete_folder', '1', true);
  update public.folders
    set deleted_at = now(),
        updated_at = now()
    where id = p_folder_id
      and deleted_at is null;
  insert into private.cleanup_jobs(operation, family_id, resource_id, metadata)
    values (
      'delete_folder',
      old.family_id,
      p_folder_id,
      jsonb_build_object(
        'owner_user_id', old.owner_user_id,
        'pet_id', old.pet_id,
        'owner_access_epoch', old.owner_access_epoch
      )
    )
    on conflict (operation, resource_id, family_id) do update
      set status = 'pending',
          attempts = 0,
          created_at = now(),
          updated_at = now(),
          metadata = excluded.metadata;
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, old.family_id, 'delete_folder', p_folder_id);
end;
$$;
