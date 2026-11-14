# Revisión de línea base TP-01 -> TP-02

No se recibió un Test Plan original de este producto; solo el enunciado de la actividad. Esta tabla reconstruye una línea base **propuesta**, no un documento previamente entregado ni una aprobación histórica.

| Apartado tradicional propuesto TP-01 | Problema en ciclo ágil | Actualización TP-02 | Evidencia esperada |
|---|---|---|---|
| Alcance único del proyecto | Pruebas al final | Alcance por sprint y HU priorizadas por riesgo | Milestone y GitHub Projects |
| QA separado del desarrollo | Hallazgos tardíos | Responsabilidad compartida, revisión cruzada | PR con revisor distinto |
| Casos manuales al concluir | Regresión costosa | TDD, BDD/ATDD y automatización continua | Rojo/verde/refactor + JSON/JUnit |
| Entorno descrito una vez | Resultados irreproducibles | Metadatos por ejecución y commit exacto | Reporte Clase XX |
| Cierre por «se terminó código» | Calidad no comprobada | DoR, DoD, seguridad, CI y aceptación | Checklist y gates |
| Métricas al entregar | Sin mejora temprana | Cobertura, pass/fail, defectos, velocidad por sprint | Métricas con denominadores |
| Riesgos estáticos | Cambios sin control | Issue, revisión de riesgo y versión del plan | Historial Git y retrospectiva |

Historial: TP-01 propuesta de referencia (14/11/2026); TP-02 v0.2 adaptación ágil preparada (14/11/2026); TP-02 v0.3 corrige arquitectura y estrategia de pruebas a Flutter + Supabase directo por aclaración del usuario (14/11/2026). Validación y firmas: pendientes de Gerardo, Eva, Waldir y docente cuando corresponda.

La actualización v0.3 reemplaza la dependencia de una API propia por Auth, PostgreSQL/RLS, RPC y Storage de Supabase. Sustituye el plan de pruebas de servidor por Supabase CLI/pgTAP y pruebas SDK/E2E. Se conserva el historial de evidencias de unidad/widget; ninguna prueba Supabase se declara ejecutada por este cambio documental.

## TP-02 v0.4 · 14/11/2026 · OPS-01 #20

Actualiza el alcance ejecutado de identidad/familia, suites SQL/Auth/Edge/concurrencia, Android real y restauración PostgreSQL local. Los resultados y fallos del dispositivo se registran en evidencias/OPS_20.md. Conserva pendientes Storage/presupuesto, accesibilidad, rendimiento, backup de objetos, rollback y aprobación humana. No sustituye la revisión del equipo/docente ni declara Done por código o suite verde.
