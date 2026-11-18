begin;
set search_path = public, extensions;
select no_plan();
insert into auth.users(id, email, email_confirmed_at) values
 ('17000000-0000-0000-0000-000000000001', 'hoja1@example.test', now()),
 ('17000000-0000-0000-0000-000000000002', 'hoja2@example.test', now()),
 ('17000000-0000-0000-0000-000000000003', 'hoja3@example.test', now());
insert into auth.sessions(id, user_id) values
 ('27000000-0000-0000-0000-000000000001', '17000000-0000-0000-0000-000000000001'),
 ('27000000-0000-0000-0000-000000000002', '17000000-0000-0000-0000-000000000002'),
 ('27000000-0000-0000-0000-000000000003', '17000000-0000-0000-0000-000000000003');
insert into public.profiles(user_id, full_name) values
 ('17000000-0000-0000-0000-000000000001', 'Titular'),
 ('17000000-0000-0000-0000-000000000002', 'Admin ajeno'),
 ('17000000-0000-0000-0000-000000000003', 'Fuera');
insert into public.families(id, name) values ('37000000-0000-0000-0000-000000000001', 'Hojas');
insert into public.memberships(family_id, user_id, is_admin) values
 ('37000000-0000-0000-0000-000000000001', '17000000-0000-0000-0000-000000000001', false),
 ('37000000-0000-0000-0000-000000000001', '17000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"17000000-0000-0000-0000-000000000001","session_id":"27000000-0000-0000-0000-000000000001"}', true);
select throws_ok($$select public.create_budget_sheet('37000000-0000-0000-0000-000000000001', ' ', gen_random_uuid())$$, 'P0001', 'validation_error', 'TC-BUD-05 HU-11: nombre obligatorio');
select lives_ok($$select public.create_budget_sheet('37000000-0000-0000-0000-000000000001', 'Casa', '47000000-0000-0000-0000-000000000001')$$, 'TC-BUD-05: miembro crea hoja propia');
select lives_ok($$select public.create_budget_sheet('37000000-0000-0000-0000-000000000001', 'Casa', '47000000-0000-0000-0000-000000000001')$$, 'TC-BUD-05: reintento idempotente');
select lives_ok($$select public.create_budget_sheet('37000000-0000-0000-0000-000000000001', 'Viaje', gen_random_uuid())$$, 'TC-BUD-05: segunda hoja del mismo titular');
select is((select count(*)::int from public.budget_sheets), 2, 'TC-BUD-05: el titular ve sus hojas');
select set_config('test.sheet_id', (select id::text from public.budget_sheets where name = 'Casa'), true);
select throws_ok($$insert into public.budget_sheets(family_id, owner_id, name) values ('37000000-0000-0000-0000-000000000001', auth.uid(), 'Directa')$$, '42501', null, 'TC-BUD-05: sin alta directa');
select throws_ok($$update public.budget_sheets set name = 'Ataque'$$, '42501', null, 'TC-BUD-05: sin editar por tabla');
select lives_ok($$select public.update_budget_sheet(current_setting('test.sheet_id')::uuid, 'Casa editada', 1)$$, 'TC-BUD-05: titular renombra');
select throws_ok($$select public.update_budget_sheet(current_setting('test.sheet_id')::uuid, 'Obsoleta', 1)$$, 'P0001', 'version_conflict', 'TC-BUD-05: versión obsoleta');
select throws_ok($$select public.delete_budget_sheet(current_setting('test.sheet_id')::uuid, 2, 'Casa')$$, 'P0001', 'validation_error', 'TC-BUD-05: borrar exige el nombre vigente');
select set_config('request.jwt.claims', '{"sub":"17000000-0000-0000-0000-000000000002","session_id":"27000000-0000-0000-0000-000000000002"}', true);
select is((select count(*)::int from public.budget_sheets), 0, 'TC-BUD-05: admin del grupo no ve finanzas ajenas');
select throws_ok($$select public.update_budget_sheet(current_setting('test.sheet_id')::uuid, 'Robo', 2)$$, '42501', 'forbidden', 'TC-BUD-05: admin no renombra hoja ajena');
select throws_ok($$select public.delete_budget_sheet(current_setting('test.sheet_id')::uuid, 2, 'Casa editada')$$, '42501', 'forbidden', 'TC-BUD-05: admin no borra hoja ajena');
select lives_ok($$select public.create_budget_sheet('37000000-0000-0000-0000-000000000001', 'Admin propia', gen_random_uuid())$$, 'TC-BUD-05: el admin sí crea su propia hoja');
select is((select count(*)::int from public.budget_sheets), 1, 'TC-BUD-05: cada quien ve solo las suyas');
select set_config('request.jwt.claims', '{"sub":"17000000-0000-0000-0000-000000000003","session_id":"27000000-0000-0000-0000-000000000003"}', true);
select throws_ok($$select public.create_budget_sheet('37000000-0000-0000-0000-000000000001', 'Intrusa', gen_random_uuid())$$, '42501', 'forbidden', 'TC-BUD-05: quien no es miembro no crea');
select set_config('request.jwt.claims', '{"sub":"17000000-0000-0000-0000-000000000001","session_id":"27000000-0000-0000-0000-000000000001"}', true);
select lives_ok($$select public.delete_budget_sheet(current_setting('test.sheet_id')::uuid, 2, 'Casa editada')$$, 'TC-BUD-05: titular borra con el nombre exacto');
select is((select count(*)::int from public.budget_sheets where name = 'Casa editada'), 0, 'TC-BUD-05: hoja borrada deja de publicarse');
reset role;
update public.memberships set active = false, is_admin = false where user_id = '17000000-0000-0000-0000-000000000001';
set local role authenticated;
select is((select count(*)::int from public.budget_sheets), 0, 'TC-BUD-05: salir del grupo oculta las hojas aunque la sesión siga viva');
select * from finish();
rollback;
