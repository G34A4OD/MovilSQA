begin;
set search_path=public,extensions;
select no_plan();

insert into auth.users(id,email,email_confirmed_at) values
 ('1b000000-0000-0000-0000-000000000001','hn1@example.test',now());
insert into auth.sessions(id,user_id) values
 ('2b000000-0000-0000-0000-000000000001','1b000000-0000-0000-0000-000000000001');
insert into public.profiles(user_id,full_name) values
 ('1b000000-0000-0000-0000-000000000001','Titular Salud');
insert into public.families(id,name) values
 ('3b000000-0000-0000-0000-000000000001','Salud Opcional');
insert into public.memberships(family_id,user_id,is_admin) values
 ('3b000000-0000-0000-0000-000000000001','1b000000-0000-0000-0000-000000000001',true);

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"1b000000-0000-0000-0000-000000000001","session_id":"2b000000-0000-0000-0000-000000000001"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id)
    values('3b000000-0000-0000-0000-000000000001','Labs','1b000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-03 HU-10: carpeta para salud general');
select set_config('test.folder',(select id::text from public.folders where name='Labs'),true);

select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Resultado laboratorio','ficticio',null,'lab.pdf',40,
    '5b000000-0000-0000-0000-000000000001',null,'health',null)$$,
  'TC-DOC-03 HU-10: salud sin tipo de nota (documento general)');
select is(
  (select health_note_kind from public.documents where title='Resultado laboratorio'),
  null,
  'TC-DOC-03 HU-10: health_note_kind null en salud general');

select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Consulta ficticia','',null,'c.pdf',20,
    '5b000000-0000-0000-0000-000000000002',null,'health','consultation')$$,
  'TC-DOC-03 HU-10: salud con nota específica sigue válida');

select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Tipo inválido','',null,'x.pdf',10,
    '5b000000-0000-0000-0000-000000000003',null,'health','laboratorio')$$,
  'P0001','validation_error','TC-DOC-03 HU-10: health_note_kind inválido rechazado');

select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'CI con nota','',null,'ci.pdf',10,
    '5b000000-0000-0000-0000-000000000004',null,'identity_civic','allergy')$$,
  'P0001','validation_error',
  'TC-DOC-03 HU-10: nota de salud no aplica fuera de categoría health');

select * from finish();
rollback;
