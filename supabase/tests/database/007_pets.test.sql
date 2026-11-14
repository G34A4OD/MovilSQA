begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('16000000-0000-0000-0000-000000000001','mascota1@example.test',now()),
 ('16000000-0000-0000-0000-000000000002','mascota2@example.test',now());
insert into auth.sessions(id,user_id) values
 ('26000000-0000-0000-0000-000000000001','16000000-0000-0000-0000-000000000001'),
 ('26000000-0000-0000-0000-000000000002','16000000-0000-0000-0000-000000000002');
insert into public.profiles(user_id,full_name) values('16000000-0000-0000-0000-000000000001','Persona Admin'),('16000000-0000-0000-0000-000000000002','Persona Miembro');
insert into public.families(id,name) values('36000000-0000-0000-0000-000000000001','Mascotas A'),('36000000-0000-0000-0000-000000000002','Mascotas B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('36000000-0000-0000-0000-000000000001','16000000-0000-0000-0000-000000000001',true),
 ('36000000-0000-0000-0000-000000000001','16000000-0000-0000-0000-000000000002',false),
 ('36000000-0000-0000-0000-000000000002','16000000-0000-0000-0000-000000000002',true);
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"16000000-0000-0000-0000-000000000001","session_id":"26000000-0000-0000-0000-000000000001"}',true);
select throws_ok($$select public.save_pet('36000000-0000-0000-0000-000000000001',null,'','Perro',null,'',null,gen_random_uuid())$$,'P0001','validation_error','TC-FAM-06 HU-07: nombre obligatorio');
select lives_ok($$select public.save_pet('36000000-0000-0000-0000-000000000001',null,'Luna ficticia','Perro','2022-01-01','Ficticio',null,'46000000-0000-0000-0000-000000000001')$$,'TC-FAM-06: alta de mascota admin');
select set_config('test.pet_id',(select id::text from public.pets),true);
select lives_ok($$select public.save_pet('36000000-0000-0000-0000-000000000001',null,'Luna ficticia','Perro','2022-01-01','Ficticio',null,'46000000-0000-0000-0000-000000000001')$$,'TC-FAM-06: alta idempotente');
select is((select count(*)::int from public.pets),1,'TC-FAM-06: sin duplicado por reintento');
select throws_ok($$update public.pets set family_id='36000000-0000-0000-0000-000000000002'$$,'42501',null,'TC-SEC-02: mascota no se transfiere por DML');
select lives_ok($$select public.save_pet('36000000-0000-0000-0000-000000000001',current_setting('test.pet_id')::uuid,'Luna editada','Perro',null,'Nota ficticia',1,gen_random_uuid())$$,'TC-FAM-06: editar mascota');
select throws_ok($$select public.delete_pet(current_setting('test.pet_id')::uuid,1)$$,'P0001','version_conflict','TC-FAM-06: borrado obsoleto denegado');
select set_config('request.jwt.claims','{"sub":"16000000-0000-0000-0000-000000000002","session_id":"26000000-0000-0000-0000-000000000002"}',true);
select is((select count(*)::int from public.pets),1,'TC-FAM-06: miembro lee mascotas familiares');
select throws_ok($$select public.delete_pet(current_setting('test.pet_id')::uuid,2)$$,'42501','forbidden','TC-FAM-06: admin de B no administra mascota de A');
select throws_ok($$select public.save_pet('36000000-0000-0000-0000-000000000002',current_setting('test.pet_id')::uuid,'Ataque','Gato',null,'',2,gen_random_uuid())$$,'P0001','pet_unavailable','TC-SEC-02: ID cruzado con propio grupo no reasigna mascota');
select set_config('request.jwt.claims','{"sub":"16000000-0000-0000-0000-000000000001","session_id":"26000000-0000-0000-0000-000000000001"}',true);
select lives_ok($$select public.delete_pet(current_setting('test.pet_id')::uuid,2)$$,'TC-FAM-06: borrado lógico por admin');
select is((select count(*)::int from public.pets),0,'TC-FAM-06: mascota borrada deja de publicarse');
reset role;
select is((select count(*)::int from auth.users where id in ('16000000-0000-0000-0000-000000000001','16000000-0000-0000-0000-000000000002')),2,'TC-FAM-06: mascota no crea cuenta Auth');
select is((select count(*)::int from private.cleanup_jobs where operation='delete_pet' and resource_id=current_setting('test.pet_id')::uuid),1,'TC-OPS-01: archivos de mascota encolados para limpieza');
select * from finish();
rollback;
