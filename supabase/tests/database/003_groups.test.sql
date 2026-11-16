begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('12000000-0000-0000-0000-000000000001','grupo1@example.test',now()),
 ('12000000-0000-0000-0000-000000000002','grupo2@example.test',now());
insert into auth.sessions(id,user_id) values
 ('22000000-0000-0000-0000-000000000001','12000000-0000-0000-0000-000000000001'),
 ('22000000-0000-0000-0000-000000000002','12000000-0000-0000-0000-000000000002');
insert into public.profiles(user_id,full_name) select id,'Persona ficticia' from auth.users where id in ('12000000-0000-0000-0000-000000000001','12000000-0000-0000-0000-000000000002');
insert into public.private_profiles(user_id,identity_card,birth_date,address) select user_id,'FICTICIO','2000-01-01','Domicilio ficticio' from public.profiles;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"12000000-0000-0000-0000-000000000001","session_id":"22000000-0000-0000-0000-000000000001"}',true);
select throws_ok($$select public.create_family('',gen_random_uuid())$$,'P0001','validation_error','TC-FAM-01 HU-03: nombre obligatorio en DB');
select lives_ok($$select public.create_family('Familia A','42000000-0000-0000-0000-000000000001')$$,'TC-FAM-01: alta grupo/admin atómica');
select set_config('test.family_id',(select id::text from public.families where name='Familia A'),true);
select is((select count(*)::int from public.memberships where is_admin),1,'TC-FAM-01: creador admin inicial');
select lives_ok($$select public.create_family('Familia A','42000000-0000-0000-0000-000000000001')$$,'TC-FAM-01: reintento misma solicitud');
select is((select count(*)::int from public.families),1,'TC-FAM-01: sin duplicado por reintento');
select lives_ok($$select public.create_family('Familia B','42000000-0000-0000-0000-000000000002')$$,'TC-FAM-01: segundo grupo del mismo usuario');
select is((select count(*)::int from public.families),2,'TC-FAM-01: multigrupo');
select lives_ok($$select public.update_family(current_setting('test.family_id')::uuid,'Familia Editada',1)$$,'TC-FAM-01: admin actualiza');
select throws_ok($$select public.update_family(current_setting('test.family_id')::uuid,'Obsoleta',1)$$,'P0001','version_conflict','TC-FAM-01: versión obsoleta denegada');
select throws_ok($$delete from public.families$$,'42501',null,'TC-SEC-02: no borrado directo');
select set_config('request.jwt.claims','{"sub":"12000000-0000-0000-0000-000000000002","session_id":"22000000-0000-0000-0000-000000000002"}',true);
select is((select count(*)::int from public.families),0,'TC-SEC-02: ajeno sin grupos');
select throws_ok($$select public.update_family(current_setting('test.family_id')::uuid,'Ataque',2)$$,'42501','forbidden','TC-SEC-02: RPC ajena denegada');
reset role;
insert into public.memberships(family_id,user_id) values(current_setting('test.family_id')::uuid,'12000000-0000-0000-0000-000000000002');
set local role authenticated;
select is((select count(*)::int from public.families),1,'TC-SEC-02: miembro ahora lee grupo');
select throws_ok($$select public.update_family(current_setting('test.family_id')::uuid,'Ataque',2)$$,'42501','forbidden','TC-SEC-02: miembro no admin no edita');
select set_config('request.jwt.claims','{"sub":"12000000-0000-0000-0000-000000000001","session_id":"22000000-0000-0000-0000-000000000001"}',true);
select throws_ok($$select public.delete_family(current_setting('test.family_id')::uuid,2,'Familia Editada')$$,'P0001','reauth_required','TC-SEC-04: borrado exige password reciente, no iat renovado');
select set_config('request.jwt.claims',jsonb_build_object('sub','12000000-0000-0000-0000-000000000001','session_id','22000000-0000-0000-0000-000000000001','amr',jsonb_build_array(jsonb_build_object('method','password','timestamp',extract(epoch from now())::bigint)))::text,true);
select throws_ok($$select public.delete_family(current_setting('test.family_id')::uuid,2,'Incorrecto')$$,'P0001','validation_error','TC-SEC-04: confirmación exacta');
select lives_ok($$select public.delete_family(current_setting('test.family_id')::uuid,2,'Familia Editada')$$,'TC-FAM-01: borrado lógico autorizado');
select is((select count(*)::int from public.families),1,'TC-SEC-02: grupo retirado ya no visible');
select set_config('request.jwt.claims','{"sub":"12000000-0000-0000-0000-000000000002","session_id":"22000000-0000-0000-0000-000000000002"}',true);
select is((select count(*)::int from public.families),0,'TC-SEC-02: borrado revoca acceso de los otros miembros');
reset role;
select is((select count(*)::int from private.cleanup_jobs where family_id=current_setting('test.family_id')::uuid and status='pending'),1,'TC-OPS-01: limpieza encolada antes de borrar metadata');
select * from finish();
rollback;
