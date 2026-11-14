# Gerardo · Identidad, familia e integración

Repositorio: https://github.com/G34A4OD/MovilSQA. Usa tu cuenta real; no hagas commits en nombre de Eva o Waldir.

## Tu participación y entregables

Implementas HU-01..07 de punta a punta (Flutter + API + DB + pruebas). Custodias integración y seguridad transversal y eres PO propuesto para validar criterios con el docente. Gerardo revisa a Eva; Waldir revisa a Gerardo. No te limitas a administrar GitHub.

| Orden | Trabajo | Evidencias |
|---|---|---|
| G0 | Invitaciones al repo, develop, Laravel, contrato y CI servidor | Issue y PR de infraestructura; configuración comprobable |
| G1 | Registro/login/logout/reset/verificación y perfil privado | HU-01/02, TC-AUTH y negativos de datos |
| G2 | CRUD grupo, lista multigrupo y buscador ID público | HU-03/04, TC-FAM-01/02 |
| G3 | Invitaciones, admins, salida/expulsión | HU-04/05, TC-FAM-03/04 concurrente en PostgreSQL |
| G4 | Parentescos sin ciclos y mascotas separadas | HU-06/07, TC-FAM-05/06 |
| G5 | Integración, staging, backup/rollback y release | TC-SEC/OPS, revisión y tag después de aceptación |

Divide filas grandes en issues de 1-3 días. Publica factories de usuarios/grupos y fixtures temprano para desbloquear a Eva/Waldir. Ellos pueden avanzar UI/dominio sobre contrato y datos ficticios; nunca integrar bypasses de permisos.

## Rutas que custodias

app/lib/features/identity/**, app/lib/features/family/**, app/test/identity/**, app/test/family/**; web/app/Modules/Identity/** y Family/**, rutas de esos módulos, migraciones de identidad/familia orden 000100/000200 y tests equivalentes.

Como integrador custodias core, main.dart, pubspec/locks, contrato API, workflow, rutas agregadoras y esquema base. Los compañeros solicitan cambios concretos mediante PR pequeño previo. No cambies un contrato consumido sin avisar en el issue y revisar impacto.

## Preparación de GitHub y Planner

1. Ejecuta gh auth login --web --git-protocol https. No compartas tokens. Comprueba nombre/correo Git propios.
2. Obtén los handles de Eva/Waldir, invítalos como colaboradores y confirma aceptación.
3. Revisa scripts/bootstrap-github.ps1 primero sin -Apply; después aplica con handles y verifica issues/asignaciones.
4. Crea develop desde la base remota, hazla default y protege main/develop con PR + una aprobación distinta + CI. Nadie aprueba su propio código.
5. Crea Planner con el equipo; sigue docs/COLABORACION.md y usa fechas reales después de confirmar disponibilidad.

## Prompt inicial para tu agente

~~~text
Trabajas conmigo, Gerardo, en Nido, proyecto SQA del equipo Gerardo/Eva/Waldir. Repo https://github.com/G34A4OD/MovilSQA. Lee AGENTS.md, README.md, docs/ESTADO.md, docs/REQUISITOS.md, docs/ARQUITECTURA.md, docs/SEGURIDAD.md, docs/SUPABASE.md, docs/api/CONTRATO.md, docs/sqa/TEST_PLAN.md, docs/COLABORACION.md y equipo/GERARDO.md. Si están los PDF locales, revisa Plan SQA móvil, Git/GitHub XP y Clases XIX/XX; si no, usa docs/FUENTES.md sin inventar contenido.

Verifica git status, remoto, rama, mi autoría, gh auth status e issues reales. Conserva cambios ajenos. Una historia por rama desde origin/develop, número real en rama/commits/PR, commits pequeños y PR hacia develop. No trabajar directo en main/develop. No generar commits de los compañeros.

Mi área: identidad y familia HU-01..07, arquitectura/seguridad e integración. No hay backend aún: inicializa Laravel en web sin sobrescribir trabajo; fija Composer/locks/PHP, Sanctum, FormRequests, Policies, Actions transaccionales y PostgreSQL de pruebas. Publica infraestructura/factories en PR previo para que Eva/Waldir trabajen. Flutter Material 3 con ViewModels/repositorios inyectados, DTOs y adaptador HTTP. La demo solo desaparece al existir reemplazo real integrado.

Implementa una HU Ready por vez: cuenta/perfil privado; CRUD grupos y lista multigrupo; ID público aleatorio exacto con límite de búsqueda; invitación solo admin, respuesta solo receptor y sin acceso pendiente; varios admins, renuncia/salida/expulsión con mínimo uno; parentescos referenciados y sin ciclos; mascotas sin cuenta. No confundir parentesco con admin. Perfil sensible requiere consentimiento por grupo; admin no cambia contraseñas ni finanzas ajenas.

Protege último admin con bloqueo de fila del grupo y transacción, más test de dos salidas concurrentes en PostgreSQL real. Prueba aceptación repetida/expirada y permiso del invitador. Seguridad en servidor aunque UI esconda botones. No usar datos reales, storage público ni credenciales DB en Flutter.

Conserva TDD rojo por causa esperada, verde y refactor. Tests positivos y negativos con TC/HU y grupos A/B, invitado pendiente/expulsado/token revocado. Ejecuta análisis, unidad/widget/API y smoke; genera reporte Clase XX con commit/build/entorno/duración/casos/fallos/stack/capturas UI. No declarar seguridad del servidor por pasar dominio Dart.

Yo reviso PR de Eva; Waldir revisa los míos. Prepara PR con EDT/HU/CU, Closes #REAL, pruebas, evidencia y riesgos. Solicita revisión real: no simules aprobación, firma, coautoría o participación de otro. Actualiza trazabilidad y Planner por historia. Termina con código probado y PR concreto revisable; informa solo bloqueos reales de credenciales/acceso/decisión humana.
~~~

## Prompt de continuación

~~~text
Continúa como agente de Gerardo siguiendo equipo/GERARDO.md. Consulta issues reales y elige la siguiente Ready de HU-01..07 con dependencias cumplidas. Implementa solo esa historia con tests negativos/positivos, reporte y PR para Waldir. Si falta aprobación docente del CU, prepara diseño/testware y registra pendiente de Ready; no la inventes. Revisa el PR de Eva acordado desde mi cuenta y con pruebas reales.
~~~

## Cierre personal

Conserva enlaces de PR propios, revisión a Eva, pruebas, Planner y acción de retrospectiva. Debes poder explicar tu módulo y los de tus compañeros; el número de PR sale de historias reales, no de aportes artificiales.


## Decisión de infraestructura confirmada

Supabase aloja PostgreSQL y Storage privado; la app consume API Laravel del stack del curso. Sanctum gestiona cuentas/sesión sin duplicarlas en Supabase Auth. Leer docs/SUPABASE.md; secretos de servidor nunca en Flutter, Git o chats. La conexión real necesita proyecto de pruebas y configuración local.

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
