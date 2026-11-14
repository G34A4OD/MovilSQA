begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('15000000-0000-0000-0000-000000000001','arbol1@example.test',now()),
 ('15000000-0000-0000-0000-000000000002','arbol2@example.test',now()),
 ('15000000-0000-0000-0000-000000000003','arbol3@example.test',now()),
 ('15000000-0000-0000-0000-000000000004','arbol4@example.test',now());
insert into auth.sessions(id,user_id) values
 ('25000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000001'),
 ('25000000-0000-0000-0000-000000000002','15000000-0000-0000-0000-000000000002');
insert into public.profiles(user_id,full_name,public_id) values
 ('15000000-0000-0000-0000-000000000001','Persona A',repeat('a',32)),
 ('15000000-0000-0000-0000-000000000002','Persona B',repeat('b',32)),
 ('15000000-0000-0000-0000-000000000003','Persona C',repeat('c',32)),
 ('15000000-0000-0000-0000-000000000004','Persona D',repeat('d',32));
insert into public.families(id,name) values('35000000-0000-0000-0000-000000000001','Árbol A'),('35000000-0000-0000-0000-000000000002','Árbol B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('35000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000001',true),
 ('35000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000002',false),
 ('35000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000003',false),
 ('35000000-0000-0000-0000-000000000002','15000000-0000-0000-0000-000000000004',true);
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"15000000-0000-0000-0000-000000000001","session_id":"25000000-0000-0000-0000-000000000001"}',true);
select lives_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000002','parent',null,'45000000-0000-0000-0000-000000000001')$$,'TC-FAM-05 HU-06: padre/hijo referenciados');
select set_config('test.rel_id',(select id::text from public.relationships where kind='parent'),true);
select lives_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000002','parent',null,'45000000-0000-0000-0000-000000000001')$$,'TC-FAM-05: reintento idempotente');
select is((select count(*)::int from public.relationships),1,'TC-FAM-05: sin vínculo duplicado');
select throws_ok($$delete from public.relationships$$,'42501',null,'TC-SEC-02: no eludir RPC del grafo');
select throws_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,auth.uid(),auth.uid(),'parent',null,gen_random_uuid())$$,'P0001','invalid_relationship','TC-FAM-05: sin autorrelación');
select throws_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000004','15000000-0000-0000-0000-000000000002','parent',null,gen_random_uuid())$$,'P0001','invalid_relationship','TC-SEC-02: extremo de otro grupo denegado');
select lives_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000002','15000000-0000-0000-0000-000000000003','parent',null,gen_random_uuid())$$,'TC-FAM-05: segunda generación');
select throws_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000003','15000000-0000-0000-0000-000000000001','parent',null,gen_random_uuid())$$,'P0001','invalid_relationship','TC-FAM-05: ciclo indirecto denegado');
select throws_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000003','15000000-0000-0000-0000-000000000001','grandparent',null,gen_random_uuid())$$,'P0001','invalid_relationship','TC-FAM-05: abuelo explícito tampoco crea ciclo');
select lives_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000003','15000000-0000-0000-0000-000000000002','sibling',null,gen_random_uuid())$$,'TC-FAM-05: hermanos normalizados');
select throws_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,'15000000-0000-0000-0000-000000000002','15000000-0000-0000-0000-000000000003','sibling',null,gen_random_uuid())$$,'P0001','invalid_relationship','TC-FAM-05: simétrico inverso no duplicado');
select lives_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',current_setting('test.rel_id')::uuid,'15000000-0000-0000-0000-000000000001','15000000-0000-0000-0000-000000000002','grandparent',1,gen_random_uuid())$$,'TC-FAM-05: editar con versión');
select throws_ok($$select public.delete_relationship('35000000-0000-0000-0000-000000000001',current_setting('test.rel_id')::uuid,1)$$,'P0001','version_conflict','TC-FAM-05: borrado obsoleto denegado');
select lives_ok($$select public.delete_relationship('35000000-0000-0000-0000-000000000001',current_setting('test.rel_id')::uuid,2)$$,'TC-FAM-05: borrar vínculo no borra personas');
select is((select count(*)::int from public.memberships),3,'TC-FAM-05: miembros conservados');
select set_config('request.jwt.claims','{"sub":"15000000-0000-0000-0000-000000000002","session_id":"25000000-0000-0000-0000-000000000002"}',true);
select throws_ok($$select public.save_relationship('35000000-0000-0000-0000-000000000001',null,auth.uid(),'15000000-0000-0000-0000-000000000003','cousin',null,gen_random_uuid())$$,'42501','forbidden','TC-FAM-05: miembro normal no asigna roles');
select lives_ok($$select public.leave_family('35000000-0000-0000-0000-000000000001')$$,'TC-SEC-02: salida de extremo del vínculo');
select set_config('request.jwt.claims','{"sub":"15000000-0000-0000-0000-000000000001","session_id":"25000000-0000-0000-0000-000000000001"}',true);
select is((select count(*)::int from public.relationships),0,'TC-SEC-02: parentescos del saliente dejan de publicarse');
select lives_ok($$select public.invite_member('35000000-0000-0000-0000-000000000001',repeat('b',32),gen_random_uuid())$$,'TC-SEC-02: reinvitación de B');
select set_config('test.inv_id',(select id::text from public.invitations where status='pending'),true);
select set_config('request.jwt.claims','{"sub":"15000000-0000-0000-0000-000000000002","session_id":"25000000-0000-0000-0000-000000000002"}',true);
select lives_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept',gen_random_uuid())$$,'TC-SEC-02: reingreso de B');
select is((select count(*)::int from public.relationships),0,'TC-SEC-02: reingreso no restaura vínculos de generación retirada');
select * from finish();
rollback;
