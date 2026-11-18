-- HU-09 / #10 · Consulta approved, update/delete/replace y descarga vía Edge.
-- Sin storage.allow_any_operation confiable: no SELECT directo en nido-documents;
-- download-document autoriza metadata y devuelve bytes (contrato fallback).

alter table private.cleanup_jobs drop constraint if exists cleanup_jobs_operation_check;
alter table private.cleanup_jobs
  add constraint cleanup_jobs_operation_check
  check (operation in (
    'delete_family',
    'remove_member',
    'delete_pet',
    'delete_account',
    'delete_folder',
    'delete_document'
  ));

alter table public.documents
  add column if not exists replaces_document_id uuid
    references public.documents(id);

create index if not exists documents_replaces_idx
  on public.documents(replaces_document_id)
  where replaces_document_id is not null and deleted_at is null;

-- Lectura de approved por miembro activo con carpeta legible y sesión viva.
create policy documents_approved_member on public.documents
for select to authenticated
using (
  deleted_at is null
  and status = 'approved'
  and private.has_live_session()
  and private.is_active_member(family_id)
  and private.folder_readable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

-- Rechazados: solo titular con permiso de escritura (como cuarentena).
create policy documents_rejected_own on public.documents
for select to authenticated
using (
  deleted_at is null
  and status = 'rejected'
  and uploaded_by = (select auth.uid())
  and private.has_live_session()
  and private.is_active_member(family_id)
  and private.folder_writable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

-- Sin policy SELECT en storage.objects para nido-documents (cliente no descarga directo).
-- createSignedUrl / listado no reciben permiso SELECT que los habilite.

drop function if exists public.begin_document_upload(uuid, text, text, date, text, bigint, uuid);
drop function if exists private.begin_document_upload(uuid, text, text, date, text, bigint, uuid);

create function private.begin_document_upload(
  p_folder_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_filename text,
  p_size_bytes bigint,
  p_request_id uuid,
  p_replaces_document_id uuid default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  folder public.folders;
  body jsonb;
  cached jsonb;
  mime text;
  doc_id uuid := gen_random_uuid();
  path text := gen_random_uuid()::text;
  result jsonb;
  replaced public.documents;
begin
  if p_request_id is null then
    raise exception 'validation_error';
  end if;
  if not private.document_title_valid(p_title) then
    raise exception 'validation_error';
  end if;
  if p_description is null or char_length(p_description) > 1000 then
    raise exception 'validation_error';
  end if;
  if p_expires_on is not null and p_expires_on < current_date then
    raise exception 'validation_error';
  end if;
  if p_size_bytes is null or p_size_bytes < 1 or p_size_bytes > 10485760 then
    raise exception 'validation_error';
  end if;
  mime := private.document_extension_mime(p_filename);

  folder := private.document_folder_live(p_folder_id);
  perform 1 from public.families where id = folder.family_id for update;
  if not private.folder_writable(
    folder.family_id, folder.owner_user_id, folder.owner_access_epoch, folder.pet_id
  ) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;

  if p_replaces_document_id is not null then
    select * into replaced
      from public.documents
      where id = p_replaces_document_id
        and deleted_at is null
      for update;
    if not found
      or replaced.folder_id <> folder.id
      or replaced.status <> 'approved'
    then
      raise exception using message = 'forbidden', errcode = '42501';
    end if;
  end if;

  body := jsonb_build_object(
    'folder_id', p_folder_id,
    'title', btrim(p_title),
    'description', coalesce(p_description, ''),
    'expires_on', p_expires_on,
    'filename', lower(btrim(p_filename)),
    'size_bytes', p_size_bytes,
    'replaces_document_id', p_replaces_document_id
  );
  cached := private.begin_request('begin_document_upload', p_request_id, body);
  if cached is not null then
    return cached;
  end if;

  insert into public.documents(
    id, family_id, folder_id, title, description, expires_on,
    declared_mime_type, size_bytes, status, storage_path, uploaded_by,
    owner_user_id, pet_id, owner_access_epoch, replaces_document_id
  ) values (
    doc_id,
    folder.family_id,
    folder.id,
    btrim(p_title),
    coalesce(p_description, ''),
    p_expires_on,
    mime,
    p_size_bytes,
    'quarantine',
    path,
    actor,
    folder.owner_user_id,
    folder.pet_id,
    folder.owner_access_epoch,
    p_replaces_document_id
  );

  result := jsonb_build_object(
    'id', doc_id,
    'folder_id', folder.id,
    'family_id', folder.family_id,
    'title', btrim(p_title),
    'description', coalesce(p_description, ''),
    'expires_on', p_expires_on,
    'declared_mime_type', mime,
    'size_bytes', p_size_bytes,
    'status', 'quarantine',
    'storage_path', path,
    'version', 1,
    'replaces_document_id', p_replaces_document_id
  );
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, folder.family_id, 'begin_document_upload', doc_id);
  return private.finish_request('begin_document_upload', p_request_id, body, result);
end;
$$;

create function public.begin_document_upload(
  p_folder_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_filename text,
  p_size_bytes bigint,
  p_request_id uuid,
  p_replaces_document_id uuid default null
) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.begin_document_upload(
    p_folder_id, p_title, p_description, p_expires_on,
    p_filename, p_size_bytes, p_request_id, p_replaces_document_id
  );
$$;

revoke all on function private.begin_document_upload(uuid, text, text, date, text, bigint, uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.begin_document_upload(uuid, text, text, date, text, bigint, uuid, uuid)
  from public, anon, authenticated;
grant execute on function private.begin_document_upload(uuid, text, text, date, text, bigint, uuid, uuid)
  to authenticated;
grant execute on function public.begin_document_upload(uuid, text, text, date, text, bigint, uuid, uuid)
  to authenticated;

-- Al aprobar un reemplazo, retirar acceso a la versión anterior.
create or replace function private.complete_document_process(
  p_document_id uuid,
  p_expected_version integer,
  p_outcome text,
  p_detected_mime text,
  p_error text,
  p_published_path text
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  doc public.documents;
  outcome text := lower(coalesce(p_outcome, ''));
  previous public.documents;
begin
  if outcome not in ('approved', 'rejected', 'quarantine') then
    raise exception 'validation_error';
  end if;
  if outcome = 'approved'
    and (
      p_detected_mime is null
      or p_detected_mime not in ('application/pdf', 'image/jpeg', 'image/png')
      or p_published_path is null
      or char_length(p_published_path) < 36
    )
  then
    raise exception 'validation_error';
  end if;
  if outcome = 'rejected'
    and p_detected_mime is not null
    and p_detected_mime not in ('application/pdf', 'image/jpeg', 'image/png')
  then
    raise exception 'validation_error';
  end if;

  select * into doc
    from public.documents
    where id = p_document_id
      and deleted_at is null
    for update;
  if not found then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version <> doc.version then
    raise exception 'version_conflict';
  end if;

  if doc.status = 'approved' then
    return jsonb_build_object(
      'id', doc.id,
      'status', doc.status,
      'version', doc.version,
      'detected_mime_type', doc.detected_mime_type,
      'published_path', doc.published_path,
      'process_attempts', doc.process_attempts,
      'last_process_error', doc.last_process_error,
      'idempotent', true
    );
  end if;

  if doc.status = 'rejected' and outcome = 'rejected' then
    return jsonb_build_object(
      'id', doc.id,
      'status', doc.status,
      'version', doc.version,
      'detected_mime_type', doc.detected_mime_type,
      'published_path', doc.published_path,
      'process_attempts', doc.process_attempts,
      'last_process_error', doc.last_process_error,
      'idempotent', true
    );
  end if;

  update public.documents
    set status = outcome,
        detected_mime_type = case
          when outcome = 'quarantine' then detected_mime_type
          else p_detected_mime
        end,
        published_path = case
          when outcome = 'approved' then p_published_path
          else published_path
        end,
        process_attempts = process_attempts + 1,
        last_process_error = case
          when outcome = 'quarantine' then left(coalesce(p_error, 'scanner_unavailable'), 200)
          when outcome = 'rejected' then left(coalesce(p_error, 'validation_error'), 200)
          else null
        end,
        version = version + 1,
        updated_at = now()
    where id = p_document_id
    returning * into doc;

  if outcome = 'approved' and doc.replaces_document_id is not null then
    select * into previous
      from public.documents
      where id = doc.replaces_document_id
        and deleted_at is null
      for update;
    if found then
      update public.documents
        set deleted_at = now(),
            version = version + 1,
            updated_at = now()
        where id = previous.id;
      insert into private.cleanup_jobs(operation, family_id, resource_id, metadata)
        values (
          'delete_document',
          previous.family_id,
          previous.id,
          jsonb_build_object(
            'storage_path', previous.storage_path,
            'published_path', previous.published_path,
            'replaced_by', doc.id
          )
        )
        on conflict (operation, resource_id, family_id) do update
          set status = 'pending',
              attempts = 0,
              created_at = now(),
              updated_at = now(),
              metadata = excluded.metadata;
    end if;
  end if;

  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (
      coalesce(doc.uploaded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      doc.family_id,
      'complete_document_process_' || outcome,
      doc.id
    );

  return jsonb_build_object(
    'id', doc.id,
    'status', doc.status,
    'version', doc.version,
    'detected_mime_type', doc.detected_mime_type,
    'published_path', doc.published_path,
    'process_attempts', doc.process_attempts,
    'last_process_error', doc.last_process_error,
    'idempotent', false
  );
end;
$$;

create or replace function private.update_document(
  p_document_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_expected_version integer
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  doc public.documents;
begin
  if not private.document_title_valid(p_title) then
    raise exception 'validation_error';
  end if;
  if p_description is null or char_length(p_description) > 1000 then
    raise exception 'validation_error';
  end if;
  if p_expires_on is not null and p_expires_on < date '1900-01-01' then
    raise exception 'validation_error';
  end if;

  select * into doc
    from public.documents
    where id = p_document_id
      and deleted_at is null
    for update;
  if not found then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  perform 1 from public.families where id = doc.family_id for update;
  if not private.folder_writable(
    doc.family_id, doc.owner_user_id, doc.owner_access_epoch, doc.pet_id
  ) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version <> doc.version then
    raise exception 'version_conflict';
  end if;

  update public.documents
    set title = btrim(p_title),
        description = coalesce(p_description, ''),
        expires_on = p_expires_on,
        version = version + 1,
        updated_at = now()
    where id = p_document_id
    returning * into doc;

  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, doc.family_id, 'update_document', doc.id);

  return jsonb_build_object(
    'id', doc.id,
    'folder_id', doc.folder_id,
    'family_id', doc.family_id,
    'title', doc.title,
    'description', doc.description,
    'expires_on', doc.expires_on,
    'declared_mime_type', doc.declared_mime_type,
    'detected_mime_type', doc.detected_mime_type,
    'size_bytes', doc.size_bytes,
    'status', doc.status,
    'storage_path', doc.storage_path,
    'published_path', doc.published_path,
    'version', doc.version
  );
end;
$$;

create function public.update_document(
  p_document_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_expected_version integer
) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.update_document(
    p_document_id, p_title, p_description, p_expires_on, p_expected_version
  );
$$;

create or replace function private.delete_document(
  p_document_id uuid,
  p_expected_version integer
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  doc public.documents;
begin
  select * into doc
    from public.documents
    where id = p_document_id
      and deleted_at is null
    for update;
  if not found then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  perform 1 from public.families where id = doc.family_id for update;
  if not private.folder_writable(
    doc.family_id, doc.owner_user_id, doc.owner_access_epoch, doc.pet_id
  ) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version <> doc.version then
    raise exception 'version_conflict';
  end if;

  update public.documents
    set deleted_at = now(),
        version = version + 1,
        updated_at = now()
    where id = p_document_id;

  insert into private.cleanup_jobs(operation, family_id, resource_id, metadata)
    values (
      'delete_document',
      doc.family_id,
      doc.id,
      jsonb_build_object(
        'storage_path', doc.storage_path,
        'published_path', doc.published_path,
        'status', doc.status
      )
    )
    on conflict (operation, resource_id, family_id) do update
      set status = 'pending',
          attempts = 0,
          created_at = now(),
          updated_at = now(),
          metadata = excluded.metadata;

  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, doc.family_id, 'delete_document', doc.id);
end;
$$;

create function public.delete_document(
  p_document_id uuid,
  p_expected_version integer
) returns void
language sql security invoker set search_path = '' as $$
  select private.delete_document(p_document_id, p_expected_version);
$$;

-- Autoriza descarga de bytes approved; usada por Edge download-document.
create or replace function private.authorize_document_download(p_document_id uuid)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  doc public.documents;
begin
  select * into doc
    from public.documents
    where id = p_document_id
      and deleted_at is null;
  if not found or doc.status <> 'approved' or doc.published_path is null then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if not private.has_live_session()
    or not private.is_active_member(doc.family_id)
    or not private.folder_readable(
      doc.family_id, doc.owner_user_id, doc.owner_access_epoch, doc.pet_id
    )
  then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  return jsonb_build_object(
    'id', doc.id,
    'folder_id', doc.folder_id,
    'family_id', doc.family_id,
    'title', doc.title,
    'status', doc.status,
    'published_path', doc.published_path,
    'detected_mime_type', coalesce(doc.detected_mime_type, doc.declared_mime_type),
    'size_bytes', doc.size_bytes,
    'version', doc.version,
    'actor_id', actor
  );
end;
$$;

create function public.authorize_document_download(p_document_id uuid) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.authorize_document_download(p_document_id);
$$;

revoke all on function private.update_document(uuid, text, text, date, integer),
  private.delete_document(uuid, integer),
  private.authorize_document_download(uuid),
  public.update_document(uuid, text, text, date, integer),
  public.delete_document(uuid, integer),
  public.authorize_document_download(uuid)
  from public, anon, authenticated;
grant execute on function private.update_document(uuid, text, text, date, integer),
  private.delete_document(uuid, integer),
  private.authorize_document_download(uuid),
  public.update_document(uuid, text, text, date, integer),
  public.delete_document(uuid, integer),
  public.authorize_document_download(uuid)
  to authenticated;

revoke all on function private.complete_document_process(uuid, integer, text, text, text, text),
  public.complete_document_process(uuid, integer, text, text, text, text)
  from public, anon, authenticated;
grant execute on function private.complete_document_process(uuid, integer, text, text, text, text),
  public.complete_document_process(uuid, integer, text, text, text, text)
  to service_role;
