# Waldir · Presupuesto, CSV, planificación y métricas

**Primero únete al repositorio:** https://github.com/G34A4OD/MovilSQA. Gerardo debe invitar tu usuario de GitHub y tú debes aceptar con tu propia cuenta. Usa identidad real Git/GH. No compartas tokens ni uses cuenta de otro integrante.

## Tu participación y entregables

Implementas HU-11..15 de punta a punta (Flutter + API Laravel + PostgreSQL + tests). Facilitas planificación/métricas como Scrum Master propuesto. Eva revisa tus PR; tú revisas los de Gerardo. La demo financiera es base de dominio, no módulo productivo terminado: tu trabajo incorpora repositorios/DTO, UI completa, API, seguridad, persistencia y descarga.

| Orden | Trabajo | Evidencias |
|---|---|---|
| W1 | Hojas propias asociadas a grupos, CRUD | HU-11, TC-BUD-05 y BOLA |
| W2 | CRUD de categorías nombre/desc/tipo | HU-12, TC-BUD-03 |
| W3 | Año 1-9999, doce meses y CRUD de movimientos | HU-13, TC-BUD-01/02 |
| W4 | Totales mensuales/anuales, déficit/superávit/equilibrio | HU-14, oráculo y múltiples hojas/años |
| W5 | Descarga real CSV por año en dispositivo | HU-15, TC-BUD-04 y parseo independiente |
| W6 | EDT/PERT/CPM, Planner, indicadores/retro y carga API | Plan, métricas con fuentes, TC-PERF-01 |

## Tus rutas

app/lib/features/budget/**, app/test/budget/**, web/app/Modules/Budget/**, web/routes/modules/budget.php, migraciones orden 000400 y web/tests/Feature/Budget/**; planificacion/** y docs/sqa/METRICAS.md. Conserva tests adversos de la base. Solicita a Gerardo cambios en core/main/dependencias/locks/contrato/CI mediante PR pequeño.

## Prompt inicial para tu agente

~~~text
Trabajas conmigo, Waldir, en Nido con Gerardo y Eva. Primero verifica que MI cuenta haya aceptado invitación como colaborador de https://github.com/G34A4OD/MovilSQA. Si falta, indica que Gerardo debe invitar mi handle y continúa trabajo local independiente. No usar credenciales/autoría ajenas. Revisa git status, remoto, rama y gh auth status; conserva cambios de otros.

Lee AGENTS.md, README.md, docs/ESTADO.md, docs/REQUISITOS.md, docs/ARQUITECTURA.md, docs/SEGURIDAD.md, docs/SUPABASE.md, docs/api/CONTRATO.md, docs/sqa/TEST_PLAN.md, docs/sqa/CASOS_PRUEBA.md, docs/COLABORACION.md y equipo/WALDIR.md. Revisa los PDF locales o docs/FUENTES.md. No declarar entregada toda la app por existir demo.

Mi módulo vertical es presupuesto HU-11..15 con Flutter Material 3 + Laravel/PostgreSQL. Evoluciona el dominio/ViewModel/UI base con repositorios/DTO/HTTP y endpoints del contrato; no crear app separada. Propietario de hoja + miembro activo son necesarios para leer/escribir/exportar; ser admin no permite finanzas ajenas. Tests BOLA/IDOR en API y descarga.

Implementa múltiples hojas propias con grupo elegido, categorías nombre/desc/tipo y CRUD. Categoría usada no se borra ni cambia de tipo hasta reasignar. Año 1-9999 con doce columnas; múltiples movimientos por mes con categoría de misma hoja, monto positivo y descripción. Separar ingresos/egresos y totales mensuales/anuales con déficit/superávit/equilibrio. Centavos enteros BOB hasta DB, nunca double; edición/borrado recalculan sin duplicar, aislamiento entre años/hojas/grupos e idempotencia de creación.

Descarga real CSV por año en Android/iOS, UTF-8/RFC4180, comillas/comas/saltos y fórmulas neutralizadas para texto (= + - @ y controles/espacios iniciales). Incluir doce resúmenes y total anual aun vacío. Comprobar con lector CSV independiente y abrir archivo real descargado, no solo buscar cadenas. Permisos de archivos mínimos y aviso de que una copia guardada no se revoca al salir del grupo.

Una issue Ready real por rama desde origin/develop; feature/NUMERO-descripcion, commits propios pequeños, PR hacia develop para Eva. Preserva módulos de compañeros y core/main/locks; cambios de contrato/dependencias mediante PR previo. Adjunta TC/HU, pruebas unit/widget/API, TDD rojo/verde/refactor, reporte commit/entorno/duración/resultados/fallos y capturas UI reales.

Actualiza PERT/CPM con scripts/plan.py: unidades, dependencias, holgura y ruta crítica. Estimación no equivale a horas trabajadas; confirma fecha/disponibilidad antes de calendario en Planner. Métricas: pass/fail/skipped, cobertura con denominador, defectos/KLOC o HU, velocidad solo de HU aceptadas y flakiness solo con histórico. Usar N/D si faltan datos. Carga en staging al existir servidor: 20 usuarios/1000 movimientos y p95/error rate medidos, nunca valores inventados.

Yo reviso PR de Gerardo; Eva revisa los míos. No simular aprobación/firma/coautoría. Cada historia termina con implementación probada, evidencia/Planner/trazabilidad y PR revisable con Closes #REAL. Explica bloqueos concretos sin abandonar trabajo independiente autorizado.
~~~

## Prompt para revisar a Gerardo

~~~text
Actúa como agente de Waldir revisor del PR de Gerardo indicado. Lee diff/contrato/tests; trae rama conservando mis cambios, ejecuta cuentas/grupos ficticios y verifica invitación pendiente/receptor incorrecto, multigrupo, último admin incluida concurrencia PostgreSQL, ciclos y mascota sin cuenta. Registra commit/entorno/pasos/esperado/actual/evidencia. Solicita correcciones concretas si falla. Aprobar solo desde mi cuenta después de probar y con autorización de esta revisión.
~~~

## Cierre personal

PR propio UI/API/DB/tests, revisión a Gerardo, CSV descargado validado, Planner/CPM, métricas reales y acción de retrospectiva. Poder defender módulos de Eva/Gerardo además del tuyo.


## Decisión de infraestructura confirmada

Supabase aloja PostgreSQL y Storage privado; la app consume API Laravel del stack del curso. Sanctum gestiona cuentas/sesión sin duplicarlas en Supabase Auth. Leer docs/SUPABASE.md; secretos de servidor nunca en Flutter, Git o chats. La conexión real necesita proyecto de pruebas y configuración local.

## Issues reales iniciales

- [HU-11 · #12](https://github.com/G34A4OD/MovilSQA/issues/12) · EDT 3.5 · S2 - Familia y archivos
- [HU-12 · #13](https://github.com/G34A4OD/MovilSQA/issues/13) · EDT 3.5 · S2 - Familia y archivos
- [HU-13 · #14](https://github.com/G34A4OD/MovilSQA/issues/14) · EDT 3.5 · S3 - Presupuesto e integración
- [HU-14 · #15](https://github.com/G34A4OD/MovilSQA/issues/15) · EDT 3.5 · S3 - Presupuesto e integración
- [HU-15 · #16](https://github.com/G34A4OD/MovilSQA/issues/16) · EDT 3.5 · S3 - Presupuesto e integración
- [QA-03 · #19](https://github.com/G34A4OD/MovilSQA/issues/19) · EDT 4.3 · S4 - Calidad y entrega

Cuenta identificada: **riblawaldir**. Invitación Write enviada; aceptar antes de push.
