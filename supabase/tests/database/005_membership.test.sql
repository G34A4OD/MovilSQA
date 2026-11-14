begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('14000000-0000-0000-0000-000000000001','admin1@example.test',now()),
 ('14000000-0000-0000-0000-000000000002','admin2@example.test',now()),
 ('14000000-0000-0000-0000-000000000003','miembro@example.test',now());
insert into auth.sessions(id,user_id) values
 ('24000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000001'),
 ('24000000-0000-0000-0000-000000000002','14000000-0000-0000-0000-000000000002'),
 ('24000000-0000-0000-0000-000000000003','14000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id,full_name) select id,'Persona ficticia' from auth.users;
insert into public.families(id,name) values('34000000-0000-0000-0000-000000000001','Grupo Admins');
insert into public.memberships(family_id,user_id,is_admin) values
 ('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000001',true),
 ('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000002',true),
 ('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000003',false);
insert into public.profile_shares(family_id,user_id,selected_fields) values('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000003','{"blood_type":"O+"}');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"14000000-0000-0000-0000-000000000003","session_id":"24000000-0000-0000-0000-000000000003"}',true);
select throws_ok($$select public.set_member_admin('34000000-0000-0000-0000-000000000001',auth.uid(),true)$$,'42501','forbidden','TC-FAM-04 HU-05: no auto promoción de miembro');
select throws_ok($$select public.remove_member('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000001')$$,'42501','forbidden','TC-FAM-04: miembro no expulsa');
select set_config('test.old_epoch',(select access_epoch::text from public.memberships where user_id=auth.uid()),true);
select lives_ok($$select public.leave_family('34000000-0000-0000-0000-000000000001')$$,'TC-FAM-04: salida propia de miembro');
select is((select count(*)::int from public.families),0,'TC-SEC-02: salida revoca grupo inmediatamente');
select ok(private.has_live_session(),'TC-SEC-03: salida no depende de invalidar JWT');
reset role;
select isnt((select access_epoch::text from public.memberships where user_id='14000000-0000-0000-0000-000000000003'),current_setting('test.old_epoch'),'TC-SEC-02: generación de acceso cambia al salir');
select is((select count(*)::int from public.profile_shares),0,'TC-PRO-03: salida retira consentimiento');
select is((select count(*)::int from private.cleanup_jobs where operation='remove_member'),1,'TC-OPS-01: limpieza asociada al saliente encolada');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"14000000-0000-0000-0000-000000000002","session_id":"24000000-0000-0000-0000-000000000002"}',true);
select lives_ok($$select public.set_member_admin('34000000-0000-0000-0000-000000000001',auth.uid(),false)$$,'TC-FAM-04: renuncia propia con otro admin');
select set_config('request.jwt.claims','{"sub":"14000000-0000-0000-0000-000000000001","session_id":"24000000-0000-0000-0000-000000000001"}',true);
select throws_ok($$select public.leave_family('34000000-0000-0000-0000-000000000001')$$,'P0001','last_admin','TC-FAM-04: último admin no sale');
select throws_ok($$select public.set_member_admin('34000000-0000-0000-0000-000000000001',auth.uid(),false)$$,'P0001','last_admin','TC-FAM-04: último admin no renuncia');
select throws_ok($$select public.remove_member('34000000-0000-0000-0000-000000000001',auth.uid())$$,'P0001','last_admin','TC-FAM-04: última administración no se expulsa');
select is((select count(*)::int from public.memberships where active and is_admin),1,'TC-FAM-04: al menos un admin tras negativos');
select lives_ok($$select public.set_member_admin('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000002',true)$$,'TC-FAM-04: admin promueve otro miembro');
select is((select count(*)::int from public.memberships where active and is_admin),2,'TC-FAM-04: varios admins');
select lives_ok($$select public.remove_member('34000000-0000-0000-0000-000000000001','14000000-0000-0000-0000-000000000002')$$,'TC-FAM-04: expulsión con otro admin restante');
select set_config('request.jwt.claims','{"sub":"14000000-0000-0000-0000-000000000002","session_id":"24000000-0000-0000-0000-000000000002"}',true);
select is((select count(*)::int from public.families),0,'TC-SEC-02: expulsado pierde acceso con sesión viva');
select throws_ok($$select public.set_member_admin('34000000-0000-0000-0000-000000000001',auth.uid(),true)$$,'42501','forbidden','TC-SEC-02: expulsado no recupera privilegios');
select * from finish();
rollback;
