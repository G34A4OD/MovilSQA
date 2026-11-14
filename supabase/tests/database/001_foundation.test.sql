-- TC-SEC-01/02/03, HU-01/02/03. Synthetic fixtures; transaction always rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select no_plan();

insert into auth.users(id,email,email_confirmed_at,is_anonymous) values
 ('10000000-0000-0000-0000-000000000001','uno@example.test',now(),false),
 ('10000000-0000-0000-0000-000000000002','dos@example.test',now(),false),
 ('10000000-0000-0000-0000-000000000003','tres@example.test',now(),false);
insert into auth.sessions(id,user_id,not_after) values
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',null),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001',null),
 ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002',null);
insert into public.profiles(user_id,full_name) values
 ('10000000-0000-0000-0000-000000000001','Persona Uno'),
 ('10000000-0000-0000-0000-000000000002','Persona Dos'),
 ('10000000-0000-0000-0000-000000000003','Persona Tres');
insert into public.private_profiles(user_id,identity_card,birth_date,address) select user_id,'FICTICIO','2000-01-01','Domicilio ficticio' from public.profiles;
insert into public.families(id,name) values
 ('30000000-0000-0000-0000-000000000001','Grupo A'),
 ('30000000-0000-0000-0000-000000000002','Grupo B');
insert into public.memberships(family_id,user_id,is_admin) values
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',true),
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',false),
 ('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003',true);

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated","session_id":"20000000-0000-0000-0000-000000000001"}',true);
select ok(private.has_live_session(),'TC-SEC-03: S1 vigente permite acceso');
select is((select count(*)::integer from public.profiles),2,'TC-SEC-01: perfil propio y familiar, no directorio global');
select is((select count(*)::integer from public.private_profiles),1,'TC-SEC-01: ni admin puede leer CI de otro familiar');
select is((select count(*)::integer from public.families),1,'TC-SEC-02: grupos A/B aislados');
select is((select count(*)::integer from public.memberships),2,'TC-SEC-02: miembros del grupo propio visibles');
select ok(private.is_family_admin('30000000-0000-0000-0000-000000000001'),'TC-FAM-01: admin propio reconocido');
select ok(not private.is_family_admin('30000000-0000-0000-0000-000000000002'),'TC-SEC-02: no admin ajeno');
select throws_ok($$update public.memberships set is_admin=true$$,'42501',null,'TC-SEC-02: no se elude RPC por UPDATE');
select throws_ok($$insert into public.families(name) values ('Intruso')$$,'42501',null,'TC-SEC-02: no alta directa sin admin inicial');
select throws_ok($$select * from auth.sessions$$,'42501',null,'TC-SEC-03: cliente nunca lee sesiones');
select throws_ok($$select * from private.request_dedup$$,'42501',null,'TC-SEC-01: tabla interna no legible');

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","session_id":"20000000-0000-0000-0000-000000000003"}',true);
select ok(not private.has_live_session(),'TC-SEC-03: session_id de otro usuario denegado');
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","session_id":"malformado"}',true);
select ok(not private.has_live_session(),'TC-SEC-03: claim malformado denegado sin excepción');
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001"}',true);
select ok(not private.has_live_session(),'TC-SEC-03: falta session_id denegado');

reset role;
delete from auth.sessions where id='20000000-0000-0000-0000-000000000001';
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated","session_id":"20000000-0000-0000-0000-000000000001"}',true);
select ok(not private.has_live_session(),'TC-SEC-03: S1 revocada aunque S2 sigue viva');
select is((select count(*)::integer from public.private_profiles),0,'TC-SEC-03: token anterior ya no lee datos privados');
select is((select count(*)::integer from public.families),0,'TC-SEC-03: token anterior ya no lee grupos');
select throws_ok($$select private.require_actor()$$,'42501','forbidden','TC-SEC-03: token anterior no puede mutar');
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","session_id":"20000000-0000-0000-0000-000000000002"}',true);
select ok(private.has_live_session(),'TC-SEC-03: sesión S2 independiente sigue permitida');
reset role;
update auth.sessions set not_after=now()-interval '1 second' where id='20000000-0000-0000-0000-000000000002';
set local role authenticated;
select ok(not private.has_live_session(),'TC-SEC-03: sesión expirada denegada');
reset role;
update auth.sessions set not_after=null where id='20000000-0000-0000-0000-000000000002';
update public.memberships set active=false,is_admin=false where user_id='10000000-0000-0000-0000-000000000001';
set local role authenticated;
select is((select count(*)::integer from public.families),0,'TC-SEC-02: membresía retirada revoca acceso con sesión viva');
select is((select count(*)::integer from public.profiles),1,'TC-SEC-02: salida conserva solo perfil propio');
reset role;
set local role anon;
select throws_ok($$select * from public.profiles$$,'42501',null,'TC-SEC-01: anónimo sin perfiles');
select throws_ok($$select private.has_live_session()$$,'42501',null,'TC-SEC-03: helper no invocable por anon');
reset role;
select ok(not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and not c.relrowsecurity),'TC-SEC-01: todas las tablas públicas con RLS');
select * from finish();
rollback;
