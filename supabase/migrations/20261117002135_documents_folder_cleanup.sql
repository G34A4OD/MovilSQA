-- HU-08 / #9. Enqueue folder cleanup atomically with delete_folder.
-- Physical purge worker remains pending; this only retires access and queues work.

alter table private.cleanup_jobs drop constraint if exists cleanup_jobs_operation_check;
alter table private.cleanup_jobs
  add constraint cleanup_jobs_operation_check
  check (operation in (
    'delete_family',
    'remove_member',
    'delete_pet',
    'delete_account',
    'delete_folder'
  ));

create or replace function private.delete_folder(
  p_folder_id uuid,
  p_expected_version integer
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
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
