# Índice de entrega SQA

Cada evidencia identifica commit/build, autor real, fecha, entorno y resultado. Tener una plantilla no significa completar el requisito.

[Incremento OPS y prueba Android real](OPS_20.md) · [G0](G0_22.md) · [HU-01](HU01_2.md) · [HU-02](HU02_3.md) · [HU-03](HU03_4.md) · [HU-04](HU04_5.md) · [HU-05](HU05_6.md) · [HU-06](HU06_7.md) · [HU-07](HU07_8.md) · [HU-08](HU08_9.md). Metadatos/resúmenes revisados en ops/, capturas ficticias en ui/.

[Reporte local validado de la base](base/report.md) · [secuencia TDD real y límites](TDD.md). Los artifacts de CI corresponden al commit probado en GitHub Actions.

| Requisito | Artefacto preparado | Falta evidencia real |
|---|---|---|
| Test Plan ágil | docs/sqa/TEST_PLAN.md y REVISION_PLAN.md | Revisión equipo/docente e historial por sprint |
| Repo y pruebas | app/test y workflow | Revisión independiente completa; Storage/presupuesto pendientes. Identidad/familia/Android y CI en evidencias OPS/HU |
| Auditoría y correctivas | docs/sqa/AUDITORIA.md | Sesión cruzada, firmas reales y revalidación |
| Tablero ágil | docs/COLABORACION.md, backlog y CPM | GitHub Projects con enlaces/capturas issues/PR |
| Resultados | scripts/verify.ps1 -> ejecuciones/ID | Cada historia, Supabase/RLS y E2E además de base |
| Indicadores/mejoras | docs/sqa/METRICAS.md | Sprints reales, denominadores y acciones |
| Clase XIX | docs/sqa/HERRAMIENTAS.md | Exportación Word/Excel, presentación y piloto |
| Clase XX | report.md/html, summary.json, junit.xml, logs | Fallos UI/dispositivo y validación humana |
| Participación | equipo/*.md y plantillas | Tres cuentas, commits/PR/revisiones/GitHub Projects |
| Release móvil | Guía tags y deploy | APK debug y SHA disponibles en OPS; faltan iOS, firma/aceptación y release final |

Ejecuciones locales se ignoran por defecto para revisar/redactar antes de subir logs. CI conserva artifacts. Para entrega local: seleccionar ejecución, revisar datos y agregar explícitamente sus archivos con git add -f. Mantener fallos relevantes y su corrección trazada.

| Persona | Issue / GitHub Projects | PR propio | PR revisado | Tests/evidencia | Retro |
|---|---|---|---|---|---|
| Gerardo | #1..8, #20, #22 / Project 1 | #21, #23..30 y OPS enlazado en #20 | De Eva, pendiente de PR real | HU01..07 y OPS_20.md | Pendiente |
| Eva | Pendiente | Pendiente | De Waldir, pendiente | Pendiente | Pendiente |
| Waldir | Pendiente | Pendiente | De Gerardo, pendiente | Pendiente | Pendiente |
