# Supabase local · G0 / issue #22

Requiere Docker iniciado, Node.js y Supabase CLI **3.1.0**. Estos comandos apuntan al entorno local; no usar reset contra el proyecto remoto.

~~~powershell
npx.cmd --yes supabase@3.1.0 start -x studio,imgproxy,realtime,logflare,vector,supavisor,edge-runtime,postgres-meta
npx.cmd --yes supabase@3.1.0 test db
npx.cmd --yes supabase@3.1.0 stop
~~~

Las pruebas bajo tests/database crean usuarios y sesiones ficticios dentro de una transacción y terminan con ROLLBACK. Las consultas y ataques se ejecutan como authenticated/anon; postgres se usa solo para preparar los fixtures. Estas pruebas no equivalen a una ejecución móvil ni prueban por sí solas el ciclo HTTP de Auth/Storage.

La configuración expone únicamente public y exige grants explícitos. private no es un schema expuesto. Ningún cliente obtiene SELECT sobre auth.sessions ni las tablas privadas. Los helpers privados definer evitan recursión RLS y validan sesión + actor derivados de Auth. Nunca confiar en user_metadata.

La migración de base crea profiles, private_profiles, profile_shares, families y memberships. Las siguientes seis migraciones agregan las RPC de HU-01..07; el cliente conserva SELECT autorizado y ejecuta las mutaciones mediante esas RPC. Eva/Waldir pueden referenciar families(id), profiles(user_id), memberships(family_id,user_id) y los helpers private.is_active_member(uuid), private.is_family_admin(uuid), private.has_live_session(). No modificar esta migración después de aplicarla; agregar otra.

Los timestamps los genera la CLI con migration new. Todo nuevo módulo debe tener versión posterior a la última dependencia real (actualmente mascotas 20261114185927); los lotes 0001xx..0004xx de la planificación inicial dejan de usarse. Comprobar migration list antes de trabajar e integrar en orden. No reinterpretar una aprobación de PR como autorización para usar datos reales.

## Suites de integración

Después de start: `python scripts/test_auth_local.py`; iniciar `npx.cmd --yes supabase@3.1.0 functions serve lookup-user` en otra terminal; ejecutar `python scripts/test_family_local.py`, `python scripts/test_membership_concurrency.py` y `python scripts/test_relationship_concurrency.py`. Todos apuntan únicamente a localhost, preparan cuentas ficticias y prueban permisos con JWT de usuarios normales; la administración local solo prepara/limpia fixtures.

Backup: `python scripts/test_backup_restore_local.py --run-id backup-NUEVO_ID`. Restaura con owners/grants a una BD temporal local, comprueba RLS como authenticated y elimina solo esa BD generada. El dump ignorado contiene fixtures; no subirlo a Git. No prueba Storage.

Android: `python scripts/test_android_local.py --device SERIAL --flutter RUTA_FLUTTER --adb RUTA_ADB --run-id android-NUEVO_ID`. Requiere teléfono autorizado, Edge local y puerto 54321 disponible para adb reverse. Usa Mailpit local y cuentas ficticias; no envía contraseñas a un servicio externo. Finalizar reinstalando lib/main.dart con la configuración normal de desarrollo; el target de integración no es una entrega.
