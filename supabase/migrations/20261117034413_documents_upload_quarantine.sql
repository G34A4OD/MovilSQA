-- HU-09 / #10 · Parte 1: metadata + reserva de carga y bucket de cuarentena.
-- process-document / escáner y bucket nido-documents quedan para el siguiente incremento.
-- Sin escáner operativo el documento permanece en status=quarantine (nunca approved aquí).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'nido-quarantine',
  'nido-quarantine',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png']::text[]
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'nido-documents',
  'nido-documents',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png']::text[]
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id),
  folder_id uuid not null,
  title text not null
    check (char_length(btrim(title)) between 1 and 100)
    check (btrim(title) !~ '[/\\]' and btrim(title) !~ '[[:cntrl:]]'),
  description text not null default ''
    check (char_length(description) <= 1000),
  expires_on date
    check (expires_on is null or expires_on >= date '1900-01-01'),
  declared_mime_type text not null
    check (declared_mime_type in ('application/pdf', 'image/jpeg', 'image/png')),
  size_bytes bigint not null
    check (size_bytes between 1 and 10485760),
  status text not null default 'quarantine'
    check (status in ('quarantine', 'approved', 'rejected')),
  storage_path text not null unique
    check (char_length(storage_path) between 36 and 200)
    check (storage_path !~ '[/\\]' and storage_path !~ '[[:cntrl:]]'),
  uploaded_by uuid not null references public.profiles(user_id),
  owner_user_id uuid,
  pet_id uuid,
  owner_access_epoch uuid,
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (family_id, id),
  check (
    (owner_user_id is not null and pet_id is null and owner_access_epoch is not null)
    or (owner_user_id is null and pet_id is not null and owner_access_epoch is null)
  ),
  foreign key (folder_id) references public.folders(id),
  foreign key (family_id, folder_id) references public.folders(family_id, id)
);

create index documents_folder_idx on public.documents(folder_id) where deleted_at is null;
create index documents_family_idx on public.documents(family_id) where deleted_at is null;
create index documents_uploader_idx on public.documents(uploaded_by) where deleted_at is null;

alter table public.documents enable row level security;
revoke all on public.documents from public, anon, authenticated;
-- Solo lectura de filas quarantine propias / approved del grupo vía policy; escrituras por RPC.
grant select on public.documents to authenticated;

create function private.document_folder_live(p_folder_id uuid) returns public.folders
language plpgsql stable security definer set search_path = '' as $$
declare folder public.folders;
begin
  select * into folder
    from public.folders f
    where f.id = p_folder_id
      and f.deleted_at is null;
  if not found then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  return folder;
end;
$$;

create function private.document_extension_mime(p_filename text) returns text
language plpgsql immutable set search_path = '' as $$
declare lower text := lower(coalesce(p_filename, ''));
begin
  if lower ~ '\.pdf$' then
    return 'application/pdf';
  end if;
  if lower ~ '\.jpe?g$' then
    return 'image/jpeg';
  end if;
  if lower ~ '\.png$' then
    return 'image/png';
  end if;
  raise exception 'validation_error';
end;
$$;

create function private.document_title_valid(p_title text) returns boolean
language sql immutable set search_path = '' as $$
  select p_title is not null
    and char_length(btrim(p_title)) between 1 and 100
    and btrim(p_title) !~ '[/\\]'
    and btrim(p_title) !~ '[[:cntrl:]]';
$$;

create or replace function private.begin_document_upload(
  p_folder_id uuid,
  p_title text,
  p_description text,
  p_expires_on date,
  p_filename text,
  p_size_bytes bigint,
  p_request_id uuid
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

  body := jsonb_build_object(
    'folder_id', p_folder_id,
    'title', btrim(p_title),
    'description', coalesce(p_description, ''),
    'expires_on', p_expires_on,
    'filename', lower(btrim(p_filename)),
    'size_bytes', p_size_bytes
  );
  cached := private.begin_request('begin_document_upload', p_request_id, body);
  if cached is not null then
    return cached;
  end if;

  insert into public.documents(
    id, family_id, folder_id, title, description, expires_on,
    declared_mime_type, size_bytes, status, storage_path, uploaded_by,
    owner_user_id, pet_id, owner_access_epoch
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
    folder.owner_access_epoch
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
    'version', 1
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
  p_request_id uuid
) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.begin_document_upload(
    p_folder_id, p_title, p_description, p_expires_on,
    p_filename, p_size_bytes, p_request_id
  );
$$;

-- Parte 1: solo el titular de la reserva ve su fila en cuarentena.
-- approved / lectura de grupo se abren en el incremento de consulta.
create policy documents_quarantine_own on public.documents
for select to authenticated
using (
  deleted_at is null
  and status = 'quarantine'
  and uploaded_by = (select auth.uid())
  and private.has_live_session()
  and private.is_active_member(family_id)
  and private.folder_writable(family_id, owner_user_id, owner_access_epoch, pet_id)
);

-- Storage: INSERT solo a la ruta reservada; sin SELECT familiar en cuarentena.
create policy quarantine_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'nido-quarantine'
  and private.has_live_session()
  and name !~ '[/\\]'
  and exists (
    select 1
    from public.documents d
    where d.storage_path = name
      and d.uploaded_by = auth.uid()
      and d.status = 'quarantine'
      and d.deleted_at is null
  )
);

-- Sin SELECT/UPDATE/DELETE de cuarentena para authenticated (proceso confiable más adelante).
-- nido-documents: sin escrituras del cliente en este incremento.

revoke all on function private.document_folder_live(uuid),
  private.document_extension_mime(text),
  private.document_title_valid(text),
  private.begin_document_upload(uuid, text, text, date, text, bigint, uuid)
  from public, anon, authenticated;
revoke all on function public.begin_document_upload(uuid, text, text, date, text, bigint, uuid)
  from public, anon, authenticated;
grant execute on function private.document_folder_live(uuid),
  private.document_extension_mime(text),
  private.document_title_valid(text),
  private.begin_document_upload(uuid, text, text, date, text, bigint, uuid)
  to authenticated;
grant execute on function public.begin_document_upload(uuid, text, text, date, text, bigint, uuid)
  to authenticated;
