begin;
set search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,email_confirmed_at) values
 ('13000000-0000-0000-0000-000000000001','invite1@example.test',now()),
 ('13000000-0000-0000-0000-000000000002','invite2@example.test',now()),
 ('13000000-0000-0000-0000-000000000003','invite3@example.test',now());
insert into auth.sessions(id,user_id) values
 ('23000000-0000-0000-0000-000000000001','13000000-0000-0000-0000-000000000001'),
 ('23000000-0000-0000-0000-000000000002','13000000-0000-0000-0000-000000000002'),
 ('23000000-0000-0000-0000-000000000003','13000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id,public_id,full_name) values
 ('13000000-0000-0000-0000-000000000001',repeat('a',32),'Persona Admin'),
 ('13000000-0000-0000-0000-000000000002',repeat('b',32),'Persona Invitada'),
 ('13000000-0000-0000-0000-000000000003',repeat('c',32),'Persona Ajena');
insert into public.families(id,name) values('33000000-0000-0000-0000-000000000001','Grupo Invitaciones');
insert into public.memberships(family_id,user_id,is_admin) values('33000000-0000-0000-0000-000000000001','13000000-0000-0000-0000-000000000001',true);
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000001","session_id":"23000000-0000-0000-0000-000000000001"}',true);
select is(public.lookup_family_user('33000000-0000-0000-0000-000000000001',repeat('b',32)),jsonb_build_object('public_id',repeat('b',32),'full_name','Persona Invitada'),'TC-FAM-02 HU-04: búsqueda mínima por ID exacto');
select is((select count(*)::int from public.profiles),1,'TC-SEC-01: buscar no abre directorio global');
select lives_ok($$select public.invite_member('33000000-0000-0000-0000-000000000001',repeat('b',32),'43000000-0000-0000-0000-000000000001')$$,'TC-FAM-02: admin invita');
select set_config('test.inv_id',(select id::text from public.invitations where status='pending'),true);
select lives_ok($$select public.invite_member('33000000-0000-0000-0000-000000000001',repeat('b',32),'43000000-0000-0000-0000-000000000001')$$,'TC-FAM-02: reintento de invitación idempotente');
select is((select count(*)::int from public.invitations),1,'TC-FAM-02: no duplica invitación');
select is(public.invite_member('33000000-0000-0000-0000-000000000001',repeat('b',32),gen_random_uuid())->>'error','invitation_unavailable','TC-FAM-02: sin duplicado pendiente y consume rate limit');
select throws_ok($$insert into public.invitations(family_id,family_name,target_user_id,target_public_id,target_name,invited_by) values('33000000-0000-0000-0000-000000000001','Ataque','13000000-0000-0000-0000-000000000003','x','x','13000000-0000-0000-0000-000000000001')$$,'42501',null,'TC-SEC-02: sin alta directa');
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000003","session_id":"23000000-0000-0000-0000-000000000003"}',true);
select is((select count(*)::int from public.invitations),0,'TC-SEC-02: ajeno no ve invitación');
select throws_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept',gen_random_uuid())$$,'P0001','invitation_unavailable','TC-FAM-03: solo receptor responde');
select throws_ok($$select public.lookup_family_user('33000000-0000-0000-0000-000000000001',repeat('b',32))$$,'42501','forbidden','TC-FAM-02: ajeno no puede buscar personas');
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000002","session_id":"23000000-0000-0000-0000-000000000002"}',true);
select is((select count(*)::int from public.invitations),1,'TC-FAM-03: receptor ve invitación sin ser miembro');
select is((select count(*)::int from public.families),0,'TC-SEC-02: pendiente no accede al grupo');
select lives_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'reject','43000000-0000-0000-0000-000000000002')$$,'TC-FAM-03: rechazo');
select is((select count(*)::int from public.memberships),0,'TC-FAM-03: rechazo no crea membresía');
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000001","session_id":"23000000-0000-0000-0000-000000000001"}',true);
select lives_ok($$select public.invite_member('33000000-0000-0000-0000-000000000001',repeat('b',32),gen_random_uuid())$$,'TC-FAM-02: reinvitar tras rechazo');
select set_config('test.inv_id',(select id::text from public.invitations where status='pending'),true);
reset role;
update public.invitations set expires_at=now()-interval '1 second' where id=current_setting('test.inv_id')::uuid;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000002","session_id":"23000000-0000-0000-0000-000000000002"}',true);
select throws_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept',gen_random_uuid())$$,'P0001','invitation_unavailable','TC-FAM-03: caducada denegada');
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000001","session_id":"23000000-0000-0000-0000-000000000001"}',true);
select lives_ok($$select public.invite_member('33000000-0000-0000-0000-000000000001',repeat('b',32),gen_random_uuid())$$,'TC-FAM-02: caducada no bloquea reinvitación');
select set_config('test.inv_id',(select id::text from public.invitations where status='pending'),true);
select lives_ok($$select public.revoke_invitation(current_setting('test.inv_id')::uuid)$$,'TC-FAM-02: revocación admin');
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000002","session_id":"23000000-0000-0000-0000-000000000002"}',true);
select throws_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept',gen_random_uuid())$$,'P0001','invitation_unavailable','TC-FAM-03: revocada no aceptable');
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000001","session_id":"23000000-0000-0000-0000-000000000001"}',true);
select lives_ok($$select public.invite_member('33000000-0000-0000-0000-000000000001',repeat('b',32),gen_random_uuid())$$,'TC-FAM-02: nueva invitación válida');
select set_config('test.inv_id',(select id::text from public.invitations where status='pending'),true);
reset role;
update public.memberships set is_admin=false where user_id='13000000-0000-0000-0000-000000000001';
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000002","session_id":"23000000-0000-0000-0000-000000000002"}',true);
select throws_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept',gen_random_uuid())$$,'P0001','invitation_unavailable','TC-FAM-03: invitador perdió admin');
reset role;
update public.memberships set is_admin=true where user_id='13000000-0000-0000-0000-000000000001';
set local role authenticated;
select lives_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept','43000000-0000-0000-0000-000000000003')$$,'TC-FAM-03: aceptación válida');
select is((select count(*)::int from public.families),1,'TC-FAM-03: aceptado ya accede al grupo');
select is((select is_admin from public.memberships where user_id=auth.uid()),false,'TC-FAM-03: aceptar nunca concede admin');
select lives_ok($$select public.respond_invitation(current_setting('test.inv_id')::uuid,'accept','43000000-0000-0000-0000-000000000003')$$,'TC-FAM-03: aceptación repetida idempotente');
select is((select count(*)::int from public.memberships where user_id=auth.uid()),1,'TC-FAM-03: sin membresía duplicada');
select throws_ok($$select public.invite_member('33000000-0000-0000-0000-000000000001',repeat('c',32),gen_random_uuid())$$,'42501','forbidden','TC-FAM-02: miembro normal no invita');
reset role;
delete from private.lookup_rate_limits;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"13000000-0000-0000-0000-000000000001","session_id":"23000000-0000-0000-0000-000000000001"}',true);
do $$ begin for n in 1..10 loop perform public.lookup_family_user('33000000-0000-0000-0000-000000000001',repeat('d',32)); end loop; end $$;
select throws_ok($$select public.lookup_family_user('33000000-0000-0000-0000-000000000001',repeat('b',32))$$,'P0001','rate_limited','TC-SEC-05: 10 búsquedas/min incluso sin coincidencia');
select * from finish();
rollback;
