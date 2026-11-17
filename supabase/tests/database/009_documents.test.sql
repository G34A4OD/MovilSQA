begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('18000000-0000-0000-0000-000000000001','doc1@example.test',now()),
 ('18000000-0000-0000-0000-000000000002','doc2@example.test',now()),
 ('18000000-0000-0000-0000-000000000003','doc3@example.test',now());
insert into auth.sessions(id,user_id) values
 ('28000000-0000-0000-0000-000000000001','18000000-0000-0000-0000-000000000001'),
 ('28000000-0000-0000-0000-000000000002','18000000-0000-0000-0000-000000000002'),
 ('28000000-0000-0000-0000-000000000003','18000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id,full_name) values
 ('18000000-0000-0000-0000-000000000001','Admin Docs'),
 ('18000000-0000-0000-0000-000000000002','Miembro Docs'),
 ('18000000-0000-0000-0000-000000000003','Ajeno Docs');
insert into public.families(id,name) values
 ('38000000-0000-0000-0000-000000000001','Docs A'),
 ('38000000-0000-0000-0000-000000000002','Docs B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('38000000-0000-0000-0000-000000000001','18000000-0000-0000-0000-000000000001',true),
 ('38000000-0000-0000-0000-000000000001','18000000-0000-0000-0000-000000000002',false),
 ('38000000-0000-0000-0000-000000000002','18000000-0000-0000-0000-000000000003',true);
insert into public.pets(id,family_id,name,species) values
 ('48000000-0000-0000-0000-000000000001','38000000-0000-0000-0000-000000000001','Luna ficticia','Perro');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"18000000-0000-0000-0000-000000000002","session_id":"28000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id)
    values('38000000-0000-0000-0000-000000000001','Salud','18000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-02 HU-09: prepara carpeta propia');
select set_config('test.folder_id',(select id::text from public.folders where name='Salud'),true);

select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'','desc',null,'a.pdf',100,
    '58000000-0000-0000-0000-000000000001')$$,
  'P0001','validation_error','TC-DOC-02 HU-09: título vacío rechazado');
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','desc',null,'a.html',100,
    '58000000-0000-0000-0000-000000000002')$$,
  'P0001','validation_error','TC-DOC-02 HU-09: extensión no permitida');
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','desc',null,'a.pdf',0,
    '58000000-0000-0000-0000-000000000003')$$,
  'P0001','validation_error','TC-DOC-02 HU-09: tamaño 0 rechazado');
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','desc',null,'a.pdf',10485761,
    '58000000-0000-0000-0000-000000000004')$$,
  'P0001','validation_error','TC-DOC-02 HU-09: más de 10 MiB rechazado');
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','desc',current_date-1,'a.pdf',100,
    '58000000-0000-0000-0000-000000000005')$$,
  'P0001','validation_error','TC-DOC-02 HU-09: vencimiento pasado rechazado');

select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','Ejemplo ficticio',null,'vacunas.pdf',1200,
    '58000000-0000-0000-0000-000000000010')$$,
  'TC-DOC-02 HU-09: reserva carga propia a cuarentena');
select set_config('test.doc_id',(select id::text from public.documents where title='Vacunas'),true);
select is((select status from public.documents where id=current_setting('test.doc_id')::uuid),'quarantine',
  'TC-DOC-02 HU-09: estado inicial quarantine (sin escáner)');
select is((select declared_mime_type from public.documents where id=current_setting('test.doc_id')::uuid),'application/pdf',
  'TC-DOC-02 HU-09: MIME declarado desde extensión');
select is((select count(*)::int from public.documents where status='approved'),0,
  'TC-DOC-02 HU-09: nada aprobado sin proceso confiable');
select is(
  (select owner_access_epoch from public.documents where id=current_setting('test.doc_id')::uuid),
  (select owner_access_epoch from public.folders where id=current_setting('test.folder_id')::uuid),
  'TC-DOC-02 HU-09: epoch sellado desde la carpeta');

-- Idempotencia
select is(
  (select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','Ejemplo ficticio',null,'vacunas.pdf',1200,
    '58000000-0000-0000-0000-000000000010')->>'id'),
  current_setting('test.doc_id'),
  'TC-DOC-02 HU-09: request_id repite el mismo document_id');

select set_config('request.jwt.claims','{"sub":"18000000-0000-0000-0000-000000000001","session_id":"28000000-0000-0000-0000-000000000001"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,pet_id)
    values('38000000-0000-0000-0000-000000000001','Vacunas mascota','48000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-02 HU-09: admin prepara carpeta de mascota');
select set_config('test.pet_folder',(select id::text from public.folders where name='Vacunas mascota'),true);
select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.pet_folder')::uuid,'Carnet','',null,'carnet.jpg',800,
    '58000000-0000-0000-0000-000000000020')$$,
  'TC-DOC-02 HU-09: admin reserva documento de carpeta de mascota');

select set_config('request.jwt.claims','{"sub":"18000000-0000-0000-0000-000000000002","session_id":"28000000-0000-0000-0000-000000000002"}',true);
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.pet_folder')::uuid,'Ajeno','',null,'a.pdf',100,
    '58000000-0000-0000-0000-000000000021')$$,
  '42501',null,'TC-DOC-03 HU-09: miembro no reserva en carpeta de mascota ajena');

select set_config('request.jwt.claims','{"sub":"18000000-0000-0000-0000-000000000003","session_id":"28000000-0000-0000-0000-000000000003"}',true);
select is((select count(*)::int from public.documents),0,'TC-DOC-03 HU-09: grupo ajeno no lee cuarentena');
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Hack','',null,'a.pdf',100,
    '58000000-0000-0000-0000-000000000030')$$,
  '42501',null,'TC-DOC-03 HU-09: ajeno no reserva en carpeta de otro grupo');

-- Mass assignment: no INSERT directo
select set_config('request.jwt.claims','{"sub":"18000000-0000-0000-0000-000000000002","session_id":"28000000-0000-0000-0000-000000000002"}',true);
select throws_ok(
  $$insert into public.documents(family_id,folder_id,title,declared_mime_type,size_bytes,status,storage_path,uploaded_by,owner_user_id,owner_access_epoch)
    values(
      '38000000-0000-0000-0000-000000000001',
      current_setting('test.folder_id')::uuid,
      'Directo','application/pdf',10,'approved','ruta-directa',
      '18000000-0000-0000-0000-000000000002',
      '18000000-0000-0000-0000-000000000002',
      (select owner_access_epoch from public.folders where id=current_setting('test.folder_id')::uuid)
    )$$,
  '42501',null,'TC-SEC-04 HU-09: INSERT directo a documents denegado');

reset role;
select is(
  (select count(*)::int from storage.buckets where id in ('nido-quarantine','nido-documents')),
  2,
  'TC-DOC-02 HU-09: buckets privados de cuarentena y documentos creados');
select is(
  (select count(*)::int from private.audit_events where operation='begin_document_upload'),
  2,
  'TC-DOC-02 HU-09: reservas dejan auditoría');

select * from finish();
rollback;
