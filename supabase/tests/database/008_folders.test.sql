begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('17000000-0000-0000-0000-000000000001','carpeta1@example.test',now()),
 ('17000000-0000-0000-0000-000000000002','carpeta2@example.test',now()),
 ('17000000-0000-0000-0000-000000000003','carpeta3@example.test',now());
insert into auth.sessions(id,user_id) values
 ('27000000-0000-0000-0000-000000000001','17000000-0000-0000-0000-000000000001'),
 ('27000000-0000-0000-0000-000000000002','17000000-0000-0000-0000-000000000002'),
 ('27000000-0000-0000-0000-000000000003','17000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id,full_name) values
 ('17000000-0000-0000-0000-000000000001','Admin Carpetas'),
 ('17000000-0000-0000-0000-000000000002','Miembro Carpetas'),
 ('17000000-0000-0000-0000-000000000003','Ajeno Carpetas');
insert into public.families(id,name) values
 ('37000000-0000-0000-0000-000000000001','Archivo A'),
 ('37000000-0000-0000-0000-000000000002','Archivo B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('37000000-0000-0000-0000-000000000001','17000000-0000-0000-0000-000000000001',true),
 ('37000000-0000-0000-0000-000000000001','17000000-0000-0000-0000-000000000002',false),
 ('37000000-0000-0000-0000-000000000002','17000000-0000-0000-0000-000000000003',true);
insert into public.pets(id,family_id,name,species) values
 ('47000000-0000-0000-0000-000000000001','37000000-0000-0000-0000-000000000001','Luna ficticia','Perro'),
 ('47000000-0000-0000-0000-000000000002','37000000-0000-0000-0000-000000000002','Michi ajeno','Gato');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"17000000-0000-0000-0000-000000000002","session_id":"27000000-0000-0000-0000-000000000002"}',true);

select throws_ok(
  $$insert into public.folders(family_id,name,owner_user_id) values('37000000-0000-0000-0000-000000000001','','17000000-0000-0000-0000-000000000002')$$,
  'P0001','validation_error','TC-DOC-01 HU-08: nombre vacío rechazado');
select throws_ok(
  $$insert into public.folders(family_id,name,owner_user_id) values('37000000-0000-0000-0000-000000000001','a/b','17000000-0000-0000-0000-000000000002')$$,
  'P0001','validation_error','TC-DOC-01 HU-08: ruta rechazada');
select throws_ok(
  $$insert into public.folders(family_id,name,owner_user_id) values('37000000-0000-0000-0000-000000000001','Salud','17000000-0000-0000-0000-000000000001')$$,
  '42501',null,'TC-DOC-01 HU-08: miembro no crea carpeta ajena');
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id) values('37000000-0000-0000-0000-000000000001','  Salud  ','17000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-01 HU-08: miembro crea carpeta propia');
select set_config('test.folder_id',(select id::text from public.folders where name='Salud'),true);
select is((select owner_access_epoch from public.folders where id=current_setting('test.folder_id')::uuid),
  (select access_epoch from public.memberships where user_id='17000000-0000-0000-0000-000000000002' and family_id='37000000-0000-0000-0000-000000000001'),
  'TC-DOC-01 HU-08: epoch sellado desde membresía vigente');
select throws_ok(
  $$insert into public.folders(family_id,name,pet_id) values('37000000-0000-0000-0000-000000000001','Vacunas mascota','47000000-0000-0000-0000-000000000001')$$,
  '42501',null,'TC-DOC-01 HU-08: miembro no crea carpeta de mascota');

select set_config('request.jwt.claims','{"sub":"17000000-0000-0000-0000-000000000001","session_id":"27000000-0000-0000-0000-000000000001"}',true);
select lives_ok(
  $$insert into public.folders(family_id,name,pet_id) values('37000000-0000-0000-0000-000000000001','Vacunas mascota','47000000-0000-0000-0000-000000000001')$$,
  'TC-DOC-01 HU-08: admin crea carpeta de mascota vigente');
select throws_ok(
  $$insert into public.folders(family_id,name,pet_id) values('37000000-0000-0000-0000-000000000001','Ajena','47000000-0000-0000-0000-000000000002')$$,
  'P0001','pet_unavailable','TC-SEC-01 HU-08: mascota de otro grupo denegada');
select is((select count(*)::int from public.folders),2,'TC-DOC-01 HU-08: admin lee carpetas del grupo');

select set_config('request.jwt.claims','{"sub":"17000000-0000-0000-0000-000000000002","session_id":"27000000-0000-0000-0000-000000000002"}',true);
select lives_ok(
  $$update public.folders set name='Salud familiar',version=1 where id=current_setting('test.folder_id')::uuid$$,
  'TC-DOC-01 HU-08: titular renombra carpeta propia');
select is((select version from public.folders where id=current_setting('test.folder_id')::uuid),2,'TC-DOC-01 HU-08: versión incrementa al renombrar');
select is(
  (select count(*)::int from public.folders where name='Vacunas mascota' and version=1),
  1,
  'TC-DOC-01 HU-08: miembro ve carpeta de mascota sin poder mutarla aún');
update public.folders set name='Hack',version=2 where name='Vacunas mascota';
select is(
  (select name from public.folders where name in ('Vacunas mascota','Hack') order by name limit 1),
  'Vacunas mascota',
  'TC-DOC-01 HU-08: miembro no renombra carpeta de mascota (0 filas por RLS)');
select throws_ok(
  $$update public.folders set owner_user_id='17000000-0000-0000-0000-000000000001',version=2 where id=current_setting('test.folder_id')::uuid$$,
  '42501',null,'TC-SEC-04 HU-08: no reasignar titular por DML');
select throws_ok(
  $$select public.delete_folder(current_setting('test.folder_id')::uuid,1)$$,
  'P0001','version_conflict','TC-DOC-01 HU-08: borrado con versión obsoleta');

select set_config('request.jwt.claims','{"sub":"17000000-0000-0000-0000-000000000003","session_id":"27000000-0000-0000-0000-000000000003"}',true);
select is((select count(*)::int from public.folders),0,'TC-SEC-01 HU-08: grupo ajeno no lee carpetas');
select throws_ok(
  $$select public.delete_folder(current_setting('test.folder_id')::uuid,2)$$,
  '42501',null,'TC-DOC-01 HU-08: ajeno no borra carpeta');

select set_config('request.jwt.claims','{"sub":"17000000-0000-0000-0000-000000000002","session_id":"27000000-0000-0000-0000-000000000002"}',true);
select set_config('test.old_epoch',(select owner_access_epoch::text from public.folders where id=current_setting('test.folder_id')::uuid),true);
select lives_ok($$select public.leave_family('37000000-0000-0000-0000-000000000001')$$,'TC-SEC-02 HU-08: salida rota generación');
select is((select count(*)::int from public.folders),0,'TC-SEC-02 HU-08: carpeta humana deja de publicarse tras salida');

reset role;
update public.memberships
  set active=true,is_admin=false,joined_at=now()
  where family_id='37000000-0000-0000-0000-000000000001'
    and user_id='17000000-0000-0000-0000-000000000002';
-- Simulate rejoin keeping the rotated epoch from leave (respond_invitation pattern).
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"17000000-0000-0000-0000-000000000002","session_id":"27000000-0000-0000-0000-000000000002"}',true);
select is((select count(*)::int from public.folders where id=current_setting('test.folder_id')::uuid),0,
  'TC-SEC-02 HU-08: reingreso no revive carpeta de generación anterior');
select isnt(
  (select access_epoch::text from public.memberships where user_id='17000000-0000-0000-0000-000000000002' and family_id='37000000-0000-0000-0000-000000000001'),
  current_setting('test.old_epoch'),
  'TC-SEC-02 HU-08: epoch vigente distinto al sellado en la carpeta');
select lives_ok(
  $$insert into public.folders(family_id,name,owner_user_id) values('37000000-0000-0000-0000-000000000001','Nueva generación','17000000-0000-0000-0000-000000000002')$$,
  'TC-DOC-01 HU-08: tras reingreso puede crear carpeta nueva');
select set_config('test.folder_id',(select id::text from public.folders where name='Nueva generación'),true);
select lives_ok(
  $$select public.delete_folder(current_setting('test.folder_id')::uuid,1)$$,
  'TC-DOC-01 HU-08: titular borra carpeta vacía');
select is((select count(*)::int from public.folders where id=current_setting('test.folder_id')::uuid),0,
  'TC-DOC-01 HU-08: carpeta eliminada');
reset role;
select is(
  (select count(*)::int from private.audit_events where operation='delete_folder' and resource_id=current_setting('test.folder_id')::uuid),
  1,
  'TC-DOC-01 HU-08: borrado deja auditoría');
select * from finish();
rollback;
