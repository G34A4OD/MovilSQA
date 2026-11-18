-- HU-09 / #10 · Parte 2: autorización y cierre de process-document.
-- Edge valida bytes reales y solo aprueba tras escaneo confiable.
-- Sin escáner acordado/operativo el documento permanece en quarantine.

alter table public.documents
  add column detected_mime_type text
    check (
      detected_mime_type is null
      or detected_mime_type in ('application/pdf', 'image/jpeg', 'image/png')
    ),
  add column published_path text
    check (
      published_path is null
      or (
        char_length(published_path) between 36 and 200
        and published_path !~ '[/\\]'
        and published_path !~ '[[:cntrl:]]'
      )
    ),
  add column process_attempts integer not null default 0
    check (process_attempts >= 0),
  add column last_process_error text
    check (last_process_error is null or char_length(last_process_error) <= 200);

create function private.authorize_document_process(p_document_id uuid) returns jsonb
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
    'version', doc.version,
    'process_attempts', doc.process_attempts,
    'last_process_error', doc.last_process_error,
    'uploaded_by', doc.uploaded_by,
    'actor_id', actor
  );
end;
$$;

create function public.authorize_document_process(p_document_id uuid) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.authorize_document_process(p_document_id);
$$;

-- Solo service_role (Edge tras autorizar al usuario). No grant a authenticated.
create function private.complete_document_process(
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

  -- Idempotencia: ya aprobado → devolver estado actual sin mutar.
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

create function public.complete_document_process(
  p_document_id uuid,
  p_expected_version integer,
  p_outcome text,
  p_detected_mime text,
  p_error text,
  p_published_path text
) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.complete_document_process(
    p_document_id, p_expected_version, p_outcome,
    p_detected_mime, p_error, p_published_path
  );
$$;

revoke all on function private.authorize_document_process(uuid),
  private.complete_document_process(uuid, integer, text, text, text, text)
  from public, anon, authenticated;
revoke all on function public.authorize_document_process(uuid),
  public.complete_document_process(uuid, integer, text, text, text, text)
  from public, anon, authenticated;

grant execute on function private.authorize_document_process(uuid),
  public.authorize_document_process(uuid)
  to authenticated;

-- complete solo para el runtime confiable (service_role), nunca el móvil.
grant execute on function private.complete_document_process(uuid, integer, text, text, text, text),
  public.complete_document_process(uuid, integer, text, text, text, text)
  to service_role;
