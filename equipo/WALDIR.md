# Waldir · Presupuesto, CSV, planificación y métricas

**Primero únete al repositorio:** https://github.com/G34A4OD/MovilSQA. Tu cuenta identificada es **riblawaldir** y se envió una invitación Write. Acepta desde tu propia cuenta antes de push/revisión. Usa tu identidad real Git/GH; no compartas tokens ni uses la cuenta de otro integrante.

## Enfoque confirmado

Nido es una app móvil Flutter + **Supabase directo**. `supabase_flutter` conecta con Auth, PostgreSQL protegido por RLS y Storage privado; RPC SQL maneja las operaciones que requieren transacciones/reglas atómicas. Edge Functions se añaden solo para procesos de confianza del contrato. No se crea otro producto ni una API propia.

La demo actual es una base de dominio en memoria, no el gestor persistente terminado. La conexión, políticas de datos, funciones y pruebas de integración se deben implementar y comprobar.

## Tu participación y entregables

Implementas HU-11..15 de punta a punta (Flutter + datos/RLS/RPC Supabase + tests). Facilitas planificación/métricas como Scrum Master propuesto. Eva revisa tus PR; tú revisas los de Gerardo.

| Orden | Trabajo | Evidencias |
|---|---|---|
| W1 | Hojas propias asociadas a grupos, CRUD | HU-11, TC-BUD-05 y negativos directos de RLS/RPC |
| W2 | CRUD de categorías nombre/desc/tipo | HU-12, TC-BUD-03; restricciones y concurrencia |
| W3 | Año 1-9999, doce meses y CRUD de movimientos | HU-13, TC-BUD-01/02 y deduplicación transaccional |
| W4 | Totales mensuales/anuales, déficit/superávit/equilibrio | HU-14, oráculo independiente y aislamiento de hojas/años |
| W5 | Descarga real CSV por año en dispositivo | HU-15, TC-BUD-04, parser independiente y autorización |
| W6 | EDT/PERT/CPM, GitHub Projects, métricas/retro y carga de consultas/RPC | Fuentes/denominadores reales y TC-PERF-01 |

## Tus rutas

- Flutter: `app/lib/features/budget/**` y `app/test/budget/**`. Conserva y amplía las pruebas adversas de la base.
- Datos: archivos propios en `supabase/migrations/`, lote inicial reservado `202611140004xx_*` (xx segundos 00-59; ejemplo válido `20261114000400_budget_base.sql`). Coordinar dependencias/versiones con Gerardo; no duplicar versiones ni editar migraciones aplicadas.
- Pruebas: `supabase/tests/budget/**`, con SQL/pgTAP y pruebas de integración mediante SDK con usuarios Auth de pruebas.
- El contrato financiero usa RPC SQL y exportación local autorizada; no crear Edge Functions financieras adicionales salvo PR previo que justifique y acuerde su nombre/firma.
- Planificación/métricas: `planificacion/**` y `docs/sqa/METRICAS.md`.

Core/main/dependencias/locks/configuración Supabase/contrato/CI tienen custodio Gerardo: solicitar un cambio pequeño previo. Los nombres de tablas, campos y RPC vienen de `docs/api/CONTRATO.md`; no crear una segunda convención de dinero, año, propietario o errores.

## Reglas financieras y permisos

Una hoja pertenece a un usuario y está vinculada a un grupo activo. RLS/RPC deben comprobar propietario y pertenencia vigente para leer/escribir/exportar. El admin de familia no ve las finanzas personales ajenas. Los IDs de hoja/categoría/movimiento aportados por Flutter se revalidan; los filtros de UI no protegen datos.

Centavos enteros BOB hasta PostgreSQL; nunca double ni redondeo implícito. Monto positivo dentro del límite del contrato, año 1-9999 y mes 1-12. Categoría de la misma hoja y tipo coherente. Una categoría usada no cambia de tipo ni se elimina hasta reasignar movimientos. Proteger el conflicto de crear movimiento mientras otra petición cambia/elimina la categoría mediante FK/restricciones y la RPC transaccional correspondiente; no resolverlo con dos consultas separadas desde Flutter.

Varias hojas, años y grupos quedan aislados. La creación se deduplica de forma atómica con el mecanismo del contrato; editar/borrar recalcula sin duplicar. CSV se genera con datos autorizados (localmente en el cliente si así lo define el contrato), UTF-8/RFC4180, doce resúmenes y total anual aun vacío. Neutralizar fórmulas solo en texto no confiable y probar comas/comillas/saltos/espacios/controles iniciales; números generados tienen formato controlado.

La URL y clave publishable/anon pueden estar en el cliente; claves secret/service_role y contraseña DB nunca. Las pruebas de permisos usan sesiones/JWT de usuarios de pruebas y solicitudes directas a datos/RPC; no solo un cliente de servicio que salta RLS. Al salir o ser expulsado del grupo, la membresía revocada debe denegar nuevas lecturas/exportaciones. Un JWT firmado y no expirado no prueba sesión activa. Es obligatorio aplicar private.has_live_session() del contrato a los datos financieros y sus RPC, contrastando session_id con auth.sessions mediante helper privado que custodia Gerardo y sin dar al móvil lectura de esa tabla. Probar lectura/mutación/exportación con sesión viva y, tras signOut con scope documentado, con el mismo JWT todavía no expirado: el guard debe denegar nuevas lecturas de filas/bytes disponibles y mutaciones sensibles. Comprobar además refresh/expiración aparte y no escribir tokens en logs. Una copia CSV ya guardada al teléfono no se puede revocar remotamente.

Configuración cliente prevista: `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`; usar la inicialización `publishableKey` de la versión fijada del SDK. `anonKey` queda como alternativa heredada si el contrato lo documenta. La plantilla `app/config/supabase.example.json` solo describe valores públicos y todavía no conecta la demo; seguir `supabase/README.md` antes de inicializar el SDK.

## Prompt inicial para tu agente

~~~text
Trabajas conmigo, Waldir, en Nido con Gerardo y Eva. Primero verifica que MI cuenta riblawaldir haya aceptado invitación como colaborador de https://github.com/G34A4OD/MovilSQA. Si falta, indica que debo aceptar o Gerardo revisar el acceso y continúa trabajo local independiente. No usar credenciales/autoría ajenas. Revisa git status, remoto, rama y gh auth status; conserva cambios de otros.

Lee AGENTS.md, README.md, docs/ESTADO.md, docs/REQUISITOS.md, docs/ARQUITECTURA.md, docs/SEGURIDAD.md, docs/SUPABASE.md, docs/api/CONTRATO.md, docs/sqa/TEST_PLAN.md, docs/sqa/CASOS_PRUEBA.md, docs/COLABORACION.md y equipo/WALDIR.md. Revisa PDF locales o docs/FUENTES.md. El usuario aclaró que el stack de otro proyecto no aplica a este producto móvil. No declarar terminada la app por existir una demo.

Mi módulo es presupuesto HU-11..15 con Flutter Material 3 + Supabase directo. Evoluciona el dominio/ViewModel/UI base con repositorios/DTO y supabase_flutter para consultas/RPC, sin crear otra app ni una API propia. Supabase Auth identifica al usuario; RLS y RPC autorizan propietario de hoja + pertenencia activa. Ser admin de familia no permite finanzas ajenas. Prueba BOLA/IDOR mediante sesiones normales de pruebas y solicitudes directas a tablas/RPC, incluida la fuente de exportación.

Implementa múltiples hojas propias con grupo elegido, categorías con nombre/desc/tipo y CRUD. Categoría usada no se borra ni cambia tipo hasta reasignar. Usa FK/restricciones y transacción/RPC del contrato para evitar carreras con creación/edición de movimientos; revocar rutas directas de mutación que evadan invariantes. No inventar nombres o parámetros: seguir docs/api/CONTRATO.md. Mis migraciones/tests están en rutas/lote de equipo/WALDIR.md; no editar migraciones aplicadas ni tocar módulos de compañeros.

Año 1-9999 con doce columnas mensuales y varios movimientos por mes, categoría de misma hoja y monto positivo. Separar ingresos/egresos, calcular totales mensuales/anuales y déficit/superávit/equilibrio. Centavos enteros BOB hasta DB, límites según contrato; nunca double. Edición/borrado recalculan, sin mezclar años/hojas/grupos. Deduplicación atómica de creación mediante el contrato, sin asumir que un doble toque o reintento no duplicará.

Descarga real CSV por año en Android/iOS con datos autorizados, UTF-8/RFC4180, comillas/comas/saltos y fórmulas neutralizadas en texto (= + - @ y controles/espacios iniciales). Incluir doce resúmenes y total anual aun vacío. Validar con lector CSV independiente y abrir el archivo real descargado; no solo buscar cadenas en strings. Pedir permisos mínimos de archivos y avisar que una copia guardada queda fuera de revocación de grupo.

URL y clave publishable/anon pueden estar en configuración cliente; secret/service_role, contraseña DB y secretos de Edge Functions nunca. RLS/RPC deben comprobar auth.uid(), membresía vigente y propietario aunque un cliente modificado cambie IDs. No usar solo service_role para probar permisos. Al salir/ser expulsado, nuevas consultas/exportaciones deben fallar por membresía revocada. Es obligatorio aplicar el guard private.has_live_session() del contrato a RLS/RPC financieros: session_id se contrasta con auth.sessions desde un helper privado y grants mínimos custodiados por Gerardo; no exponer auth.sessions al móvil. Una firma JWT válida no demuestra sesión viva. Prueba primero lectura/mutación/exportación autorizada con sesión vigente; captura el JWT en fixture seguro sin loguearlo, ejecuta signOut con scope documentado y repite con ese JWT aún no expirado: no deben devolverse filas/bytes sensibles ni aceptarse mutaciones. Limpiar sesión/caches y validar refresh/expiración por separado; no presentar una promesa de invalidación criptográfica inmediata como si fuera el guard ya probado.

Una issue Ready real por rama desde origin/develop; feature/NUMERO-descripcion, commits propios pequeños y PR hacia develop para Eva. Cambios de core/main/pubspec/locks/config/contrato/CI por PR previo a Gerardo. Adjunta TC/HU, tests unit/widget, SQL/pgTAP de RLS/restricciones/RPC e integración de datos con usuarios de pruebas. TDD rojo/verde/refactor y reporte con commit/entorno/duración/resultados/fallos/capturas UI reales. Lo no ejecutado queda planificado, sin inventar resultados.

Actualiza PERT/CPM con scripts/plan.py: unidades, dependencias, holgura y ruta crítica. Estimación no equivale a horas trabajadas; confirma fecha/disponibilidad antes de GitHub Projects. Métricas con denominadores: pass/fail/skipped, cobertura, defectos/KLOC o HU, velocidad de HU aceptadas y flakiness con histórico. N/D si faltan datos. Al existir integración de pruebas, medir carga reproducible de consultas/RPC (20 usuarios/1000 movimientos por hoja), p95 y errores; no inventar valores ni usar producción.

Yo reviso PR de Gerardo; Eva revisa los míos. No simular aprobación/firma/coautoría. Cada historia termina con implementación probada, evidencia/GitHub Projects/trazabilidad y PR revisable con Closes #REAL. Explica bloqueos concretos sin abandonar trabajo independiente autorizado.
~~~

## Prompt para revisar a Gerardo

~~~text
Actúa como agente de Waldir para revisar el PR de Gerardo indicado. Lee diff/contrato/tests; trae rama preservando mis cambios y ejecuta cuentas/grupos ficticios mediante Auth/SDK/RPC. Verifica invitación pendiente/receptor incorrecto, multigrupo, auto escalado, último admin con dos transacciones PostgreSQL concurrentes, ciclos y mascota sin cuenta. Comprueba que no se pueda eludir la RPC alterando tablas directamente; RLS/grants deben denegarlo. Verifica private.has_live_session()/session_id y grants privados sin lectura pública de auth.sessions: controles positivos con sesión viva y negativos de filas/bytes/mutaciones tras signOut usando JWT aún no expirado. Diferencia este guard de la comprobación de membresía y de expiración/revocación de sesión Auth; logout no invalida criptográficamente el JWT por sí solo. Registra commit/entorno/pasos/esperado/actual/evidencia. Solicita correcciones concretas si falla; aprueba solo desde mi cuenta tras probar y con autorización de esta revisión.
~~~

## Cierre personal

PR propio Flutter/datos/RLS/RPC/tests, revisión a Gerardo, CSV descargado validado, GitHub Projects/CPM, métricas reales y acción de retrospectiva. Poder defender módulos de Eva/Gerardo además del tuyo.

## Issues reales iniciales

- [HU-11 · #12](https://github.com/G34A4OD/MovilSQA/issues/12) · EDT 3.5 · S2 - Familia y archivos
- [HU-12 · #13](https://github.com/G34A4OD/MovilSQA/issues/13) · EDT 3.5 · S2 - Familia y archivos
- [HU-13 · #14](https://github.com/G34A4OD/MovilSQA/issues/14) · EDT 3.5 · S3 - Presupuesto e integración
- [HU-14 · #15](https://github.com/G34A4OD/MovilSQA/issues/15) · EDT 3.5 · S3 - Presupuesto e integración
- [HU-15 · #16](https://github.com/G34A4OD/MovilSQA/issues/16) · EDT 3.5 · S3 - Presupuesto e integración
- [QA-03 · #19](https://github.com/G34A4OD/MovilSQA/issues/19) · EDT 4.3 · S4 - Calidad y entrega

Cuenta identificada: **riblawaldir**. Invitación Write enviada; aceptar antes de push.
