begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('11000000-0000-0000-0000-000000000001','perfil1@example.test',now()),
 ('11000000-0000-0000-0000-000000000002','perfil2@example.test',now());
insert into auth.sessions(id,user_id) values
 ('21000000-0000-0000-0000-000000000001','11000000-0000-0000-0000-000000000001'),
 ('21000000-0000-0000-0000-000000000002','11000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11000000-0000-0000-0000-000000000001","session_id":"21000000-0000-0000-0000-000000000001"}',true);
select throws_ok($$select public.complete_profile('','A+','123','2000-01-01','Domicilio ficticio')$$,'P0001','validation_error','TC-PRO-01 HU-02: validación DB sin cambios parciales');
select is((select count(*)::int from public.profiles),0,'TC-PRO-01: alta inválida no crea perfil parcial');
select lives_ok($$select public.complete_profile('Persona Uno','A+','FICTICIO1','2000-01-01','Domicilio ficticio')$$,'TC-PRO-01: perfil completo atómico');
select matches((select public_id from public.profiles),'^[0-9a-f]{32}$','TC-PRO-02: ID aleatorio opaco no CI');
select throws_ok($$select public.complete_profile('Otro nombre','O+','FICTICIO2','2000-01-01','Domicilio ficticio')$$,'P0001','profile_exists','TC-PRO-01: alta repetida no sobrescribe versión');
select throws_ok($$update public.profiles set public_id='falso'$$,'42501',null,'TC-PRO-02: ID público inmutable por DML');
select lives_ok($$select public.update_profile('Persona Actualizada','O+','FICTICIO2','2000-01-01','Domicilio ficticio',1)$$,'TC-PRO-01: edición versionada');
select throws_ok($$select public.update_profile('Edición obsoleta','O+','FICTICIO3','2000-01-01','Domicilio ficticio',1)$$,'P0001','version_conflict','TC-PRO-01: conflicto optimista');
select is((select identity_card from public.private_profiles),'FICTICIO2','TC-PRO-01: datos preservados tras conflicto');
select throws_ok($$select private.profile_result('11000000-0000-0000-0000-000000000002')$$,'42501',null,'TC-SEC-01: helper privado no expone otro perfil');
select throws_ok($$select private.finish_request('x',gen_random_uuid(),'{}','{}')$$,'42501',null,'TC-SEC-02: no envenenar deduplicación');
reset role;
insert into public.profiles(user_id,full_name) values('11000000-0000-0000-0000-000000000002','Persona Dos');
insert into public.families(id,name) values('31000000-0000-0000-0000-000000000001','Grupo Consentimiento');
insert into public.memberships(family_id,user_id,is_admin) values
 ('31000000-0000-0000-0000-000000000001','11000000-0000-0000-0000-000000000001',true),
 ('31000000-0000-0000-0000-000000000001','11000000-0000-0000-0000-000000000002',false);
set local role authenticated;
select throws_ok($$select public.set_profile_share('31000000-0000-0000-0000-000000000001',array['user_id'],'41000000-0000-0000-0000-000000000001')$$,'P0001','validation_error','TC-PRO-03: lista permitida');
select lives_ok($$select public.set_profile_share('31000000-0000-0000-0000-000000000001',array['blood_type'],'41000000-0000-0000-0000-000000000001')$$,'TC-PRO-03: consentimiento explícito');
select is((select selected_fields from public.profile_shares),'{"blood_type":"O+"}'::jsonb,'TC-PRO-03: sin CI ni domicilio');
select lives_ok($$select public.set_profile_share('31000000-0000-0000-0000-000000000001',array['blood_type'],'41000000-0000-0000-0000-000000000001')$$,'TC-PRO-03: reintento idempotente');
select is((select version from public.profile_shares),1,'TC-PRO-03: reintento no duplica consentimiento');
select throws_ok($$select public.set_profile_share('31000000-0000-0000-0000-000000000001',array['address'],'41000000-0000-0000-0000-000000000001')$$,'P0001','request_conflict','TC-PRO-03: request reutilizado con otro cuerpo');
select set_config('request.jwt.claims','{"sub":"11000000-0000-0000-0000-000000000002","session_id":"21000000-0000-0000-0000-000000000002"}',true);
select is((select selected_fields from public.profile_shares where user_id='11000000-0000-0000-0000-000000000001'),'{"blood_type":"O+"}'::jsonb,'TC-PRO-03: familiar lee snapshot consentido');
select is((select count(*)::int from public.private_profiles),0,'TC-SEC-01: familiar no lee perfil privado');
reset role;
delete from auth.sessions where id='21000000-0000-0000-0000-000000000002';
set local role authenticated;
select throws_ok($$select public.complete_profile('Persona Dos','A+','FICTICIO','2000-01-01','Domicilio ficticio')$$,'42501','forbidden','TC-SEC-03: RPC deniega sesión revocada');
select * from finish();
rollback;
