# Supabase local · G0 / issue #22

Requiere Docker iniciado, Node.js y Supabase CLI **3.1.0**. Estos comandos apuntan al entorno local; no usar reset contra el proyecto remoto.

~~~powershell
npx.cmd --yes supabase@3.1.0 start -x studio,imgproxy,realtime,logflare,vector,supavisor,edge-runtime,postgres-meta
npx.cmd --yes supabase@3.1.0 test db
npx.cmd --yes supabase@3.1.0 stop
~~~

Las pruebas bajo tests/database crean usuarios y sesiones ficticios dentro de una transacción y terminan con ROLLBACK. Las consultas y ataques se ejecutan como authenticated/anon; postgres se usa solo para preparar los fixtures. Estas pruebas no equivalen a una ejecución móvil ni prueban por sí solas el ciclo HTTP de Auth/Storage.

La configuración expone únicamente public y exige grants explícitos. private no es un schema expuesto. Ningún cliente obtiene SELECT sobre auth.sessions ni las tablas privadas. Los helpers privados definer evitan recursión RLS y validan sesión + actor derivados de Auth. Nunca confiar en user_metadata.

La migración de base crea profiles, private_profiles, profile_shares, families y memberships. No ofrece aún las RPC de HU-01..07: hasta entregarlas, el cliente solo tiene SELECT autorizado. Eva/Waldir pueden referenciar families(id), profiles(user_id), memberships(family_id,user_id) y los helpers private.is_active_member(uuid), private.is_family_admin(uuid), private.has_live_session(). No modificar esta migración después de aplicarla; agregar otra.

Los timestamps los genera la CLI con migration new. Todo nuevo módulo debe tener versión posterior a 20261114163113 y a sus dependencias; los lotes 0001xx..0004xx de la planificación inicial dejan de usarse. Comprobar migration list antes de trabajar e integrar en orden. No reinterpretar una aprobación de PR como autorización para usar datos reales.
