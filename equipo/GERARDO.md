# Gerardo · Identidad, familia e integración

Repositorio: https://github.com/G34A4OD/MovilSQA. Usa tu cuenta real **G34A4OD**; no hagas commits en nombre de Eva o Waldir.

## Enfoque confirmado

El producto es una app móvil Flutter + **Supabase directo**: `supabase_flutter`, Supabase Auth, PostgreSQL con RLS, Storage privado y funciones SQL/RPC para operaciones transaccionales. Edge Functions se añaden únicamente cuando un proceso de confianza lo necesite. El alcance actual no incluye un producto web ni una API propia.

La base actual sigue siendo una demostración en memoria; estas instrucciones describen el trabajo por implementar y probar, no un backend conectado ni permisos ya validados.

## Tu participación y entregables

Implementas HU-01..07 de punta a punta (Flutter + Auth/datos/RLS/RPC + pruebas). Custodias integración y seguridad transversal y eres PO propuesto para validar criterios con el docente. Gerardo revisa a Eva; Waldir revisa a Gerardo. Tu participación incluye desarrollo, pruebas y corrección de defectos.

| Orden | Trabajo | Evidencias |
|---|---|---|
| G0 | Proyecto Supabase de pruebas, configuración SDK, esquema y contrato compartidos, RLS base y CI de datos | Issue y PR pequeños de infraestructura; configuración comprobable y fixtures sintéticos |
| G1 | Registro/verificación/login/logout/recuperación con Auth y perfil privado | HU-01/02, TC-AUTH; seguridad de sesión y lecturas directas negativas |
| G2 | CRUD de grupos, lista multigrupo y búsqueda exacta de ID público | HU-03/04, TC-FAM-01/02 y aislamiento por RLS |
| G3 | Invitaciones, varios admins, renuncia/salida/expulsión | HU-04/05, RPC transaccionales y TC-FAM-03/04 concurrente en PostgreSQL |
| G4 | Parentescos sin ciclos y mascotas separadas | HU-06/07, TC-FAM-05/06; grafo y permisos comprobados |
| G5 | Integración móvil, entorno de pruebas, backup/restauración y release | TC-SEC/OPS, revisión independiente y tag después de aceptación |

Divide filas grandes en issues de 1-3 días. Publica temprano migraciones, fixtures y contratos para que Eva/Waldir puedan avanzar con datos ficticios. Nadie debe abrir permisos globales o desactivar RLS para desbloquear una pantalla.

## Rutas que custodias

- Flutter: `app/lib/features/identity/**`, `app/lib/features/family/**`, `app/test/identity/**`, `app/test/family/**`.
- Datos: migraciones propias en `supabase/migrations/` y tests de SQL/pgTAP en `supabase/tests/identity/**` y `supabase/tests/family/**`.
- Edge Functions del contrato de identidad/familia: `supabase/functions/delete-account/**` y `supabase/functions/lookup-user/**`. Las demás reglas críticas de tu módulo son RPC SQL con los nombres y grants del contrato.
- Integración: `core`, `main.dart`, `pubspec.yaml` y locks, `supabase/config.toml`, configuración de entorno de ejemplo, contrato compartido y CI.

Coordina versiones de migración por timestamp válido, sin dos archivos con la misma versión. Lote inicial reservado: `202611140001xx_*` para identidad y `202611140002xx_*` para familia; sustituir xx por segundos 00-59 antes de crear archivos, por ejemplo `20261114000100_identity_base.sql`. Eva usa lote 0003xx y Waldir 0004xx. Si hace falta otro lote o cambia el orden de dependencias, acordarlo antes del PR. Nunca editar una migración ya aplicada: agregar otra.

Los compañeros solicitan cambios de composición, dependencias, configuración o contrato mediante PR pequeño previo. Los nombres de tablas, funciones y parámetros se toman de `docs/api/CONTRATO.md`; no crear variantes incompatibles mientras otro agente implementa un consumidor.

## Seguridad obligatoria en Supabase

La URL del proyecto y una clave **publishable/anon** pueden formar parte de la configuración cliente; no son la barrera de autorización. Claves **secret/service_role**, contraseña de PostgreSQL y secretos de escaneo solo en entornos confiables, nunca en Flutter, Git o prompts. Una clave de servicio puede saltar RLS y no debe usarse para demostrar acceso normal de un miembro.

Habilita RLS y permisos mínimos de tablas/Storage. Las consultas seguras comprueban `auth.uid()`, pertenencia activa al grupo y propiedad del recurso. La UI no decide seguridad. Perfil sensible separado de los datos mínimos de búsqueda; un ID público exacto no revela CI, domicilio o salud.

Las mutaciones delicadas pasan por RPC SQL del contrato, con transacción, autorización interna y grants mínimos. Para último admin: bloquear la fila del grupo, revalidar permisos y contar admins en la misma transacción. Probar dos salidas/degradaciones simultáneas en PostgreSQL real. Revocar mutaciones directas que permitirían eludir esta regla; una función privilegiada debe fijar un search_path seguro y validar al llamador, sin confiar en user_id enviado por Flutter.

Supabase Auth gestiona sesión/refresh. Cerrar sesión elimina la sesión local y revoca refresh según el alcance elegido, pero no garantiza invalidar instantáneamente un JWT ya emitido: puede seguir válido hasta expirar. La expulsión/salida de un grupo sí debe denegar nuevas peticiones por comprobación vigente de membresía en RLS/RPC/Storage. Para los datos sensibles es obligatorio implementar y probar `private.has_live_session()` del contrato: contrastar el claim `session_id` con la sesión vigente en `auth.sessions`, desde un helper restringido y sin dar al móvil lectura de esa tabla. Incorporar el guard a RLS/RPC y las políticas de Storage, además de membresía/propiedad. Gerardo custodia el helper, su esquema privado y los grants mínimos; no es una opción diferible a la UI. Una firma JWT válida no demuestra una sesión activa.

## Preparación de GitHub y GitHub Projects

1. Comprueba `gh auth status` y nombre/correo Git propios. No compartas tokens.
2. Las invitaciones Write se enviaron a Eva/pizzatoev y Waldir/riblawaldir; comprobar aceptación actual antes de asignar o solicitar revisión.
3. Sigue `docs/GITHUB_ESTADO.md` y `docs/COLABORACION.md`: base en PR #21, develop como integración y ramas protegidas. No recrear ni debilitar protecciones existentes.
4. Revisa `scripts/bootstrap-github.ps1` sin -Apply; tras aceptar invitaciones, -Apply completa asignaciones de issues existentes sin duplicarlas.
5. GitHub Projects se completa con el equipo y con fechas confirmadas; no inventar un calendario ni firmas.

Configuración cliente prevista: `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`; usar la inicialización `publishableKey` de la versión fijada del SDK. `anonKey` queda como alternativa heredada si el contrato lo documenta. La plantilla `app/config/supabase.example.json` solo describe valores públicos y todavía no conecta la demo; seguir `supabase/README.md` antes de inicializar el SDK.

## Prompt inicial para tu agente

~~~text
Trabajas conmigo, Gerardo, en Nido, proyecto móvil SQA del equipo Gerardo/Eva/Waldir. Repo https://github.com/G34A4OD/MovilSQA. Lee AGENTS.md, README.md, docs/ESTADO.md, docs/REQUISITOS.md, docs/ARQUITECTURA.md, docs/SEGURIDAD.md, docs/SUPABASE.md, docs/api/CONTRATO.md, docs/sqa/TEST_PLAN.md, docs/COLABORACION.md y equipo/GERARDO.md. Si están los PDF locales, revisa Plan SQA móvil y las clases XP/XIX/XX; el usuario aclaró que el stack de otro proyecto no restringe este proyecto móvil. Si faltan, usa docs/FUENTES.md sin inventar contenido.

Verifica git status, remoto, rama, mi autoría, gh auth status e issues reales. Conserva cambios ajenos. Una historia por rama desde origin/develop, número real en rama/commits/PR y commits pequeños. No trabajar directo en main/develop ni hacer commits de compañeros. La base debe estar integrada antes de iniciar historias dependientes.

Arquitectura: Flutter Material 3 + Supabase directo mediante supabase_flutter, Auth, PostgreSQL/RLS, Storage privado y RPC SQL. No crear un segundo producto ni una API propia. Mi área es HU-01..07, configuración y seguridad compartidas. Prepara proyecto local/de pruebas, migraciones y fixtures; pide solo identificadores públicos y configuración local segura cuando hagan falta credenciales. Usa repositorios inyectados, DTOs y ViewModels; la demo sigue explícita hasta que el reemplazo real esté integrado y probado.

Publica primero infraestructura/contrato/RLS/fixtures en PR pequeño para Eva/Waldir. Mantén nombres y parámetros exactos de docs/api/CONTRATO.md. Respeta sus rutas y lotes de migración; coordina core/main/pubspec/locks/config/CI antes de cambiarlos. No editar migraciones aplicadas.

Implementa una HU Ready por vez: cuenta/perfil privado con Supabase Auth; CRUD y listado multigrupo; ID público aleatorio exacto y búsqueda limitada; invitación solo admin y respuesta solo receptor, sin acceso pendiente; varios admins con renuncia/salida/expulsión y mínimo uno; parentescos referenciados sin ciclos; mascotas sin cuenta. Parentesco no concede admin; el admin no cambia contraseñas ni finanzas ajenas. Compartir datos sensibles requiere consentimiento por grupo.

RLS y RPC son autoridad aunque la UI o un cliente modificado cambien IDs. Verificar auth.uid(), membresía vigente y propiedad. Clave publishable/anon puede estar en cliente; secret/service_role y contraseña DB nunca. Funciones privilegiadas con permisos mínimos y search_path seguro. Las mutaciones que alteran admins deben quedar bloqueadas para CRUD directo y ejecutarse por RPC transaccional: lock de fila del grupo, revalidación y conteo dentro de la misma transacción. Probar dos peticiones concurrentes reales. Validar receptor/estado/vigencia/invitador al responder invitación y evitar ciclos de ascendencia también bajo concurrencia.

No afirmar revocación criptográfica instantánea al logout: un JWT ya emitido puede seguir firmado y sin expirar. Implementa obligatoriamente private.has_live_session() como define el contrato: contrasta session_id con auth.sessions mediante helper privado restringido, sin exponer auth.sessions al cliente, e incorpóralo a accesos sensibles en RLS/RPC/Storage. Yo custodio su implementación y grants. Prueba explícitamente un JWT capturado en un fixture seguro antes de signOut: verifica sesión viva durante el caso positivo y terminada en el caso negativo, y comprueba que nuevas lecturas de filas/bytes y mutaciones sensibles sean denegadas aun sin haber expirado el token. Usa el scope de signOut documentado y no pongas tokens en logs. Prueba aparte expulsión/salida con membresía vigente en cada petición. No usar datos reales ni acceso público a archivos.

Conserva TDD rojo por causa esperada, verde y refactor. Tests positivos/negativos con TC/HU: Dart/widget, SQL/pgTAP para restricciones/RLS/RPC y pruebas de integración con usuarios Auth reales de pruebas y grupos A/B. No probar todo con service_role ni dar seguridad por demostrada por tests Dart. Ejecuta CI/smoke pertinente y genera reporte Clase XX con commit/build/entorno/duración/casos/fallos/logs/capturas UI. Si infraestructura de datos aún no existe, registrar pruebas planificadas sin inventar resultados.

Yo reviso PR de Eva; Waldir revisa los míos. Prepara PR hacia develop con EDT/HU/CU, Closes #REAL, pruebas/evidencias y riesgos. Solicita revisión real, sin simular aprobación, firma, coautoría o participación. Actualiza trazabilidad/GitHub Projects. Termina con código probado y PR concreto revisable; informa bloqueos reales de acceso o decisión humana mientras avanzas en trabajo independiente autorizado.
~~~

## Prompt de continuación

~~~text
Continúa como agente de Gerardo siguiendo equipo/GERARDO.md y el contrato Supabase actual. Consulta issues reales y elige la siguiente Ready de HU-01..07 con dependencias cumplidas. Implementa solo esa historia con tests positivos/negativos de RLS/RPC y Flutter, incluidos guard de sesión viva y JWT aún válido tras signOut cuando la historia accede a datos sensibles, evidencia y PR para Waldir. Si falta aprobación docente del CU, prepara diseño/testware y registra pendiente de Ready; no la inventes. Revisa el PR de Eva acordado desde mi cuenta con pruebas reales.
~~~

## Cierre personal

Conserva enlaces de PR propios, revisión a Eva, pruebas, GitHub Projects y acción de retrospectiva. Debes poder explicar tu módulo y los de tus compañeros; el número de PR sale de historias reales, no de aportes artificiales.

## Issues reales iniciales

- [PREP-01 · #1](https://github.com/G34A4OD/MovilSQA/issues/1) · EDT 1.0 · S1 - Base e identidad
- [HU-01 · #2](https://github.com/G34A4OD/MovilSQA/issues/2) · EDT 3.1 · S1 - Base e identidad
- [HU-02 · #3](https://github.com/G34A4OD/MovilSQA/issues/3) · EDT 3.1 · S1 - Base e identidad
- [HU-03 · #4](https://github.com/G34A4OD/MovilSQA/issues/4) · EDT 3.2 · S2 - Familia y archivos
- [HU-04 · #5](https://github.com/G34A4OD/MovilSQA/issues/5) · EDT 3.2 · S2 - Familia y archivos
- [HU-05 · #6](https://github.com/G34A4OD/MovilSQA/issues/6) · EDT 3.2 · S2 - Familia y archivos
- [HU-06 · #7](https://github.com/G34A4OD/MovilSQA/issues/7) · EDT 3.3 · S3 - Presupuesto e integración
- [HU-07 · #8](https://github.com/G34A4OD/MovilSQA/issues/8) · EDT 3.3 · S3 - Presupuesto e integración
- [OPS-01 · #20](https://github.com/G34A4OD/MovilSQA/issues/20) · EDT 5.1 · S4 - Calidad y entrega
