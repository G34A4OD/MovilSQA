begin;
set search_path=public,extensions;
select no_plan();

insert into auth.users(id,email,email_confirmed_at) values
 ('19000000-0000-0000-0000-000000000001','c1@example.test',now()),
 ('19000000-0000-0000-0000-000000000002','c2@example.test',now()),
 ('19000000-0000-0000-0000-000000000003','c3@example.test',now());
insert into auth.sessions(id,user_id) values
 ('29000000-0000-0000-0000-000000000001','19000000-0000-0000-0000-000000000001'),
 ('29000000-0000-0000-0000-000000000002','19000000-0000-0000-0000-000000000002'),
 ('29000000-0000-0000-0000-000000000003','19000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id,full_name) values
 ('19000000-0000-0000-0000-000000000001','Admin Consulta'),
 ('19000000-0000-0000-0000-000000000002','Miembro Consulta'),
 ('19000000-0000-0000-0000-000000000003','Ajeno Consulta');
insert into public.families(id,name) values
 ('39000000-0000-0000-0000-000000000001','Consulta A'),
 ('39000000-0000-0000-0000-000000000002','Consulta B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('39000000-0000-0000-0000-000000000001','19000000-0000-0000-0000-000000000001',true),
 ('39000000-0000-0000-0000-000000000001','19000000-0000-0000-0000-000000000002',false),
 ('39000000-0000-0000-0000-000000000002','19000000-0000-0000-0000-000000000003',true);

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id)
    values('39000000-0000-0000-0000-000000000001','Salud G1','19000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-03 HU-09: prepara carpeta G1');
select set_config('test.folder',(select id::text from public.folders where name='Salud G1'),true);
select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Vacunas','ficticio',null,'a.pdf',100,
    '59000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-03 HU-09: reserva documento');
select set_config('test.doc',(select id::text from public.documents where title='Vacunas'),true);
select set_config('test.path',(select storage_path from public.documents where id=current_setting('test.doc')::uuid),true);

-- Completions como postgres (security definer); runtime Edge usa service_role.
reset role;
select is(
  (select public.complete_document_process(
    current_setting('test.doc')::uuid,1,'approved','application/pdf',null,current_setting('test.path')
  )->>'status'),
  'approved',
  'TC-DOC-03 HU-09: aprueba tras proceso confiable');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select is(
  (select count(*)::int from public.documents where id=current_setting('test.doc')::uuid and status='approved'),
  1,'TC-DOC-03 HU-09: titular lee approved en G1');
select lives_ok(
  $$select public.authorize_document_download(current_setting('test.doc')::uuid)$$,
  'TC-DOC-04 HU-09: miembro activo autoriza descarga');

select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000001","session_id":"29000000-0000-0000-0000-000000000001"}',true);
select is(
  (select count(*)::int from public.documents where id=current_setting('test.doc')::uuid),
  1,'TC-DOC-03 HU-09: otro miembro de G1 lee approved');
select lives_ok(
  $$select public.authorize_document_download(current_setting('test.doc')::uuid)$$,
  'TC-DOC-03 HU-09: admin G1 también descarga');

select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000003","session_id":"29000000-0000-0000-0000-000000000003"}',true);
select is(
  (select count(*)::int from public.documents where id=current_setting('test.doc')::uuid),
  0,'TC-DOC-03 HU-09: miembro de G2 no lee documento de G1');
select throws_ok(
  $$select public.authorize_document_download(current_setting('test.doc')::uuid)$$,
  '42501','forbidden','TC-DOC-03 HU-09: G2 no autoriza descarga');

select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000001","session_id":"29000000-0000-0000-0000-000000000001"}',true);
select throws_ok(
  $$select public.update_document(
    current_setting('test.doc')::uuid,'Hack','',null,1)$$,
  'P0001','version_conflict','TC-DOC-03 HU-09: version_conflict en edición');
select lives_ok(
  $$select public.update_document(
    current_setting('test.doc')::uuid,'Vacunas actualizadas','nota admin',null,2)$$,
  'TC-DOC-03 HU-09: admin modera metadata auditado');
select is((select title from public.documents where id=current_setting('test.doc')::uuid),
  'Vacunas actualizadas','TC-DOC-03 HU-09: título actualizado');

select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000003","session_id":"29000000-0000-0000-0000-000000000003"}',true);
select throws_ok(
  $$select public.update_document(
    current_setting('test.doc')::uuid,'Intruso','',null,3)$$,
  '42501','forbidden','TC-DOC-03 HU-09: ajeno no escribe metadata');

select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Vacunas v2','reemplazo',null,'b.pdf',200,
    '59000000-0000-0000-0000-000000000010', current_setting('test.doc')::uuid)$$,
  'TC-DOC-02 HU-09: reserva reemplazo sin sobrescribir approved');
select set_config('test.rep',(select id::text from public.documents where title='Vacunas v2'),true);
select set_config('test.reppath',(select storage_path from public.documents where id=current_setting('test.rep')::uuid),true);
select is((select status from public.documents where id=current_setting('test.doc')::uuid),'approved',
  'TC-DOC-02 HU-09: original sigue approved hasta escaneo del reemplazo');

reset role;
select is(
  (select public.complete_document_process(
    current_setting('test.rep')::uuid,1,'approved','application/pdf',null,current_setting('test.reppath')
  )->>'status'),
  'approved',
  'TC-DOC-02 HU-09: aprueba reemplazo');
select is((select deleted_at is not null from public.documents where id=current_setting('test.doc')::uuid),
  true,'TC-DOC-02 HU-09: versión anterior retirada tras reemplazo');
select is(
  (select count(*)::int from private.cleanup_jobs
    where operation='delete_document' and resource_id=current_setting('test.doc')::uuid),
  1,'TC-DOC-02 HU-09: encola limpieza del replaced');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$select public.delete_document(current_setting('test.rep')::uuid,2)$$,
  'TC-DOC-03 HU-09: titular elimina propio');
select is((select count(*)::int from public.documents
  where id=current_setting('test.rep')::uuid and deleted_at is null),0,
  'TC-DOC-03 HU-09: eliminado no visible');
select throws_ok(
  $$select public.authorize_document_download(current_setting('test.rep')::uuid)$$,
  '42501','forbidden','TC-DOC-04 HU-09: descarga denegada tras eliminar');

select is(
  (select count(*)::int from pg_policies
    where schemaname='storage' and tablename='objects'
      and qual ilike '%nido-documents%' and cmd='SELECT'),
  0,'TC-DOC-04 HU-09: sin policy SELECT storage nido-documents (fallback Edge)');

select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Post leave','',null,'c.pdf',50,
    '59000000-0000-0000-0000-000000000020')$$,
  'TC-DOC-04 HU-09: prepara doc para revocación');
select set_config('test.leave',(select id::text from public.documents where title='Post leave'),true);
select set_config('test.leavepath',(select storage_path from public.documents where id=current_setting('test.leave')::uuid),true);

reset role;
select is(
  (select public.complete_document_process(
    current_setting('test.leave')::uuid,1,'approved','application/pdf',null,current_setting('test.leavepath')
  )->>'status'),
  'approved',
  'TC-DOC-04 HU-09: aprueba doc de revocación');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"19000000-0000-0000-0000-000000000002","session_id":"29000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$select public.leave_family('39000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-04 HU-09: miembro sale del grupo');
select throws_ok(
  $$select public.authorize_document_download(current_setting('test.leave')::uuid)$$,
  '42501','forbidden','TC-DOC-04 HU-09: JWT vigente tras leave no descarga');
select is(
  (select count(*)::int from public.documents where id=current_setting('test.leave')::uuid),
  0,'TC-DOC-04 HU-09: RLS deja de devolver filas tras leave');

select * from finish();
rollback;
