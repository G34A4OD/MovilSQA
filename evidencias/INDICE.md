# Índice de entrega SQA

Cada evidencia identifica commit/build, autor real, fecha, entorno y resultado. Tener una plantilla no significa completar el requisito.

[Reporte local validado de la base](base/report.md) · [secuencia TDD real y límites](TDD.md). Los artifacts de CI corresponden al commit probado en GitHub Actions.

| Requisito | Artefacto preparado | Falta evidencia real |
|---|---|---|
| Test Plan ágil | docs/sqa/TEST_PLAN.md y REVISION_PLAN.md | Revisión equipo/docente e historial por sprint |
| Repo y pruebas | app/test y workflow | PR, CI remoto, RLS/RPC/Auth/Storage y dispositivo |
| Auditoría y correctivas | docs/sqa/AUDITORIA.md | Sesión cruzada, firmas reales y revalidación |
| Tablero ágil | docs/COLABORACION.md, backlog y CPM | Planner con enlaces/capturas issues/PR |
| Resultados | scripts/verify.ps1 -> ejecuciones/ID | Cada historia, Supabase/RLS y E2E además de base |
| Indicadores/mejoras | docs/sqa/METRICAS.md | Sprints reales, denominadores y acciones |
| Clase XIX | docs/sqa/HERRAMIENTAS.md | Exportación Word/Excel, presentación y piloto |
| Clase XX | report.md/html, summary.json, junit.xml, logs | Fallos UI/dispositivo y validación humana |
| Participación | equipo/*.md y plantillas | Tres cuentas, commits/PR/revisiones/Planner |
| Release móvil | Guía tags y deploy | APK, SHA-256, Android/iOS, release y demo |

Ejecuciones locales se ignoran por defecto para revisar/redactar antes de subir logs. CI conserva artifacts. Para entrega local: seleccionar ejecución, revisar datos y agregar explícitamente sus archivos con git add -f. Mantener fallos relevantes y su corrección trazada.

| Persona | Issue / Planner | PR propio | PR revisado | Tests/evidencia | Retro |
|---|---|---|---|---|---|
| Gerardo | Pendiente | Pendiente | De Eva, pendiente | Pendiente | Pendiente |
| Eva | Pendiente | Pendiente | De Waldir, pendiente | Pendiente | Pendiente |
| Waldir | Pendiente | Pendiente | De Gerardo, pendiente | Pendiente | Pendiente |
