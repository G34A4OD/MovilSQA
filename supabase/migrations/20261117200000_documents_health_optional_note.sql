-- HU-10 / #11 · Salud puede ser documento general sin health_note_kind.
-- No edita 20261117162000 (ya aplicada); relaja constraint y RPC.

alter table public.documents
  drop constraint if exists documents_health_note_category_check;

alter table public.documents
  add constraint documents_health_note_category_check
  check (
    health_note_kind is null
    or (
      category = 'health'
      and health_note_kind in ('allergy', 'consultation', 'prescription', 'vaccine')
    )
  );

create or replace function private.begin_document_upload(
  p_folder_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_filename text,
  p_size_bytes bigint,
  p_request_id uuid,
  p_replaces_document_id uuid default null,
  p_category text default 'identity_civic',
  p_health_note_kind text default null
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
  category text := lower(coalesce(nullif(p_category, ''), 'identity_civic'));
  note_kind text := nullif(lower(coalesce(p_health_note_kind, '')), '');
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
  if category not in ('identity_civic', 'civil_life', 'social_labor_tax', 'health') then
    raise exception 'validation_error';
  end if;
  if category = 'health' then
    if note_kind is not null
      and note_kind not in ('allergy', 'consultation', 'prescription', 'vaccine')
    then
      raise exception 'validation_error';
    end if;
  else
    if note_kind is not null then
      raise exception 'validation_error';
    end if;
    note_kind := null;
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
    'replaces_document_id', p_replaces_document_id,
    'category', category,
    'health_note_kind', note_kind
  );
  cached := private.begin_request('begin_document_upload', p_request_id, body);
  if cached is not null then
    return cached;
  end if;

  insert into public.documents(
    id, family_id, folder_id, title, description, expires_on,
    declared_mime_type, size_bytes, status, storage_path, uploaded_by,
    owner_user_id, pet_id, owner_access_epoch, replaces_document_id,
    category, health_note_kind
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
    p_replaces_document_id,
    category,
    note_kind
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
    'replaces_document_id', p_replaces_document_id,
    'category', category,
    'health_note_kind', note_kind,
    'uploaded_by', actor,
    'created_at', now()
  );
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, folder.family_id, 'begin_document_upload', doc_id);
  return private.finish_request('begin_document_upload', p_request_id, body, result);
end;
$$;

create or replace function private.update_document(
  p_document_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_expected_version integer,
  p_category text default null,
  p_health_note_kind text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  doc public.documents;
  v_category text;
  v_note_kind text;
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

  v_category := lower(coalesce(p_category, doc.category));
  if v_category not in ('identity_civic', 'civil_life', 'social_labor_tax', 'health') then
    raise exception 'validation_error';
  end if;
  if v_category = 'health' then
    -- null = conservar; '' = documento general de salud sin nota específica.
    if p_health_note_kind is null then
      v_note_kind := doc.health_note_kind;
    else
      v_note_kind := nullif(lower(p_health_note_kind), '');
    end if;
    if v_note_kind is not null
      and v_note_kind not in ('allergy', 'consultation', 'prescription', 'vaccine')
    then
      raise exception 'validation_error';
    end if;
  else
    v_note_kind := null;
  end if;

  update public.documents
    set title = btrim(p_title),
        description = coalesce(p_description, ''),
        expires_on = p_expires_on,
        category = v_category,
        health_note_kind = v_note_kind,
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
    'version', doc.version,
    'category', doc.category,
    'health_note_kind', doc.health_note_kind,
    'uploaded_by', doc.uploaded_by,
    'created_at', doc.created_at,
    'updated_at', doc.updated_at
  );
end;
$$;
