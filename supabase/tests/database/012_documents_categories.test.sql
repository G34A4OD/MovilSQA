begin;
set search_path=public,extensions;
select no_plan();

insert into auth.users(id,email,email_confirmed_at) values
 ('1a000000-0000-0000-0000-000000000001','cat1@example.test',now()),
 ('1a000000-0000-0000-0000-000000000002','cat2@example.test',now());
insert into auth.sessions(id,user_id) values
 ('2a000000-0000-0000-0000-000000000001','1a000000-0000-0000-0000-000000000001'),
 ('2a000000-0000-0000-0000-000000000002','1a000000-0000-0000-0000-000000000002');
insert into public.profiles(user_id,full_name) values
 ('1a000000-0000-0000-0000-000000000001','Admin Cat'),
 ('1a000000-0000-0000-0000-000000000002','Miembro Cat');
insert into public.families(id,name) values
 ('3a000000-0000-0000-0000-000000000001','Cat Familia');
insert into public.memberships(family_id,user_id,is_admin) values
 ('3a000000-0000-0000-0000-000000000001','1a000000-0000-0000-0000-000000000001',true),
 ('3a000000-0000-0000-0000-000000000001','1a000000-0000-0000-0000-000000000002',false);
insert into public.pets(id,family_id,name,species) values
 ('4a000000-0000-0000-0000-000000000001','3a000000-0000-0000-0000-000000000001','Nube ficticia','Gato');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"1a000000-0000-0000-0000-000000000002","session_id":"2a000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id)
    values('3a000000-0000-0000-0000-000000000001','Docs Cat','1a000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-03 HU-10: carpeta humana');
select set_config('test.folder',(select id::text from public.folders where name='Docs Cat'),true);

select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Alergia','',null,'a.pdf',10,
    '5a000000-0000-0000-0000-000000000001',null,'health',null)$$,
  'P0001','validation_error','TC-DOC-03 HU-10: salud exige tipo de nota');

select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'Alergia a polvo','ficticio',null,'a.pdf',10,
    '5a000000-0000-0000-0000-000000000002',null,'health','allergy')$$,
  'TC-DOC-03 HU-10: nota de alergia con autor y categoría salud');
select set_config('test.allergy',(select id::text from public.documents where title='Alergia a polvo'),true);
select is((select category from public.documents where id=current_setting('test.allergy')::uuid),'health',
  'TC-DOC-03 HU-10: categoría salud');
select is((select health_note_kind from public.documents where id=current_setting('test.allergy')::uuid),'allergy',
  'TC-DOC-03 HU-10: kind allergy');
select is((select uploaded_by from public.documents where id=current_setting('test.allergy')::uuid),
  '1a000000-0000-0000-0000-000000000002'::uuid,
  'TC-DOC-03 HU-10: autor = uploaded_by');

select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.folder')::uuid,'CI ficticio','',null,'ci.pdf',20,
    '5a000000-0000-0000-0000-000000000003',null,'identity_civic',null)$$,
  'TC-DOC-03 HU-10: categoría identidad/cívico');

select set_config('request.jwt.claims','{"sub":"1a000000-0000-0000-0000-000000000001","session_id":"2a000000-0000-0000-0000-000000000001"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,pet_id)
    values('3a000000-0000-0000-0000-000000000001','Salud mascota','4a000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-03 HU-10: admin crea carpeta de mascota');
select set_config('test.petfolder',(select id::text from public.folders where name='Salud mascota'),true);
select lives_ok(
  $$select public.begin_document_upload(
    current_setting('test.petfolder')::uuid,'Vacuna rabia','nota mascota',null,'v.pdf',30,
    '5a000000-0000-0000-0000-000000000010',null,'health','vaccine')$$,
  'TC-DOC-03 HU-10: admin registra vacuna de mascota');

select set_config('request.jwt.claims','{"sub":"1a000000-0000-0000-0000-000000000002","session_id":"2a000000-0000-0000-0000-000000000002"}',true);
select throws_ok(
  $$select public.begin_document_upload(
    current_setting('test.petfolder')::uuid,'Intruso','',null,'x.pdf',10,
    '5a000000-0000-0000-0000-000000000011',null,'health','vaccine')$$,
  '42501','forbidden','TC-DOC-03 HU-10: miembro no escribe carpeta de mascota');

-- Admin modera metadata de salud del miembro.
select set_config('request.jwt.claims','{"sub":"1a000000-0000-0000-0000-000000000001","session_id":"2a000000-0000-0000-0000-000000000001"}',true);
select lives_ok(
  $$select public.update_document(
    current_setting('test.allergy')::uuid,'Alergia actualizada','moderado',null,1,'health','allergy')$$,
  'TC-DOC-03 HU-10: admin modera nota de salud');

select * from finish();
rollback;
