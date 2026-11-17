begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('19000000-0000-0000-0000-000000000001','proc1@example.test',now()),
 ('19000000-0000-0000-0000-000000000002','proc2@example.test',now()),
 ('19000000-0000-0000-0000-000000000003','proc3@example.test',now());
insert into auth.sessions(id,user_id) values
 ('29000000-0000-0000-0000-000000000001','19000000-0000-0000-0000-000000000001'),
 ('29000000-0000-0000-0000-000000000002','19000000-0000-0000-0000-000000000002'),
 ('29000000-0000-0000-0000-000000000003','19000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id,full_name) values
 ('19000000-0000-0000-0000-000000000001','Admin Proc'),
 ('19000000-0000-0000-0000-000000000002','Miembro Proc'),
 ('19000000-0000-0000-0000-000000000003','Ajeno Proc');
insert into public.families(id,name) values
 ('39000000-0000-0000-0000-000000000001','Proc A'),
 ('39000000-0000-0000-0000-000000000002','Proc B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('39000000-0000-0000-0000-000000000001','19000000-0000-0000-0000-000000000001',true),
 ('39000000-0000-0000-0000-000000000001','19000000-0000-0000-0000-000000000002',false),
 ('39000000-0000-0000-0000-000000000002','19000000-0000-0000-0000-000000000003',true);

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id)
    values('39000000-0000-0000-0000-000000000001','Proc Salud','19000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-02 HU-09: carpeta para process');
select set_config('test.folder_id',(select id::text from public.folders where name='Proc Salud'),true);
select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Vacunas','',null,'vacunas.pdf',8,
    '59000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-02 HU-09: reserva documento a procesar');
select set_config('test.doc_id',(select id::text from public.documents where title='Vacunas' and folder_id=current_setting('test.folder_id')::uuid),true);

select lives_ok(
  $$select public.authorize_document_process(current_setting('test.doc_id')::uuid)$$,
  'TC-DOC-02 HU-09: titular autoriza process-document');
select is(
  (select public.authorize_document_process(current_setting('test.doc_id')::uuid)->>'status'),
  'quarantine',
  'TC-DOC-02 HU-09: authorize expone cuarentena');

select throws_ok(
  $$select public.complete_document_process(
    current_setting('test.doc_id')::uuid,1,'approved','application/pdf',null,
    (select storage_path from public.documents where id=current_setting('test.doc_id')::uuid))$$,
  '42501',null,
  'TC-DOC-02 HU-09: authenticated no puede completar process');

select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000003","session_id":"29000000-0000-0000-0000-000000000003"}',true);
select throws_ok(
  $$select public.authorize_document_process(current_setting('test.doc_id')::uuid)$$,
  '42501',null,
  'TC-DOC-03 HU-09: ajeno no autoriza process-document');

reset role;
-- Completions usan security definer; se invocan como postgres de prueba
-- (service_role en runtime Edge). authenticated ya no tiene EXECUTE.
select set_config('test.complete1',(
  select public.complete_document_process(
    current_setting('test.doc_id')::uuid,1,'quarantine','application/pdf','scanner_unavailable',null
  )::text
),true);
select is(
  (current_setting('test.complete1')::jsonb->>'status'),
  'quarantine',
  'TC-DOC-02 HU-09: sin escáner permanece quarantine');
select is(
  (current_setting('test.complete1')::jsonb->>'process_attempts')::int,
  1,
  'TC-DOC-02 HU-09: intento de process registrado');
select is(
  (current_setting('test.complete1')::jsonb->>'last_process_error'),
  'scanner_unavailable',
  'TC-DOC-02 HU-09: error de escáner conservado');

select is(
  (select (public.complete_document_process(
    current_setting('test.doc_id')::uuid,2,'quarantine','application/pdf','scanner_unavailable',null
  )->>'process_attempts')::int),
  2,
  'TC-DOC-02 HU-09: reintento sin escáner suma attempts');

select is(
  (select public.complete_document_process(
    current_setting('test.doc_id')::uuid,3,'rejected',null,'signature_invalid',null
  )->>'status'),
  'rejected',
  'TC-DOC-02 HU-09: firma inválida deja rejected');

select is(
  (select public.complete_document_process(
    current_setting('test.doc_id')::uuid,4,'rejected',null,'signature_invalid',null
  )->>'idempotent'),
  'true',
  'TC-DOC-02 HU-09: reintento rejected es idempotente');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder_id')::uuid,'Carnet','',null,'carnet.jpg',10,
    '59000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-02 HU-09: segunda reserva para approved');
select set_config('test.doc2',(select id::text from public.documents where title='Carnet'),true);
select set_config('test.path2',(select storage_path from public.documents where id=current_setting('test.doc2')::uuid),true);

reset role;
select is(
  (select public.complete_document_process(
    current_setting('test.doc2')::uuid,1,'approved','image/jpeg',null,current_setting('test.path2')
  )->>'status'),
  'approved',
  'TC-DOC-02 HU-09: complete approved tras escaneo confiable');
select is(
  (select public.complete_document_process(
    current_setting('test.doc2')::uuid,2,'approved','image/jpeg',null,current_setting('test.path2')
  )->>'idempotent'),
  'true',
  'TC-DOC-02 HU-09: reintento approved es idempotente');

select * from finish();
rollback;
