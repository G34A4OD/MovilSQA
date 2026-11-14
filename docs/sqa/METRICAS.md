# Registro de indicadores

Las cifras reales de unidad/widget y cobertura están en cada `evidencias/ejecuciones/<id>/report.md` generado por el script. Nunca copiar aquí un porcentaje de cobertura como si fuera aceptación de toda la app.

| Métrica | Estado inicial / fuente | Actualización |
|---|---|---|
| Pasados/fallidos/saltados | Ver reporte de la ejecución más reciente y su raw JSON | Automática por ejecución |
| Cobertura instrumentada de líneas | Ver lcov y reporte; incluye solo lo instrumentado | Automática por ejecución |
| HU aceptadas / HU del sprint | N/D; sprint y aceptación aún no ejecutados | Waldir después de review |
| Defectos confirmados / KLOC | N/D; no hay baseline de bugs aceptados ni KLOC acordadas | Waldir, excluye código generado/vendor |
| Velocidad (puntos) | N/D; ninguna historia aceptada de un sprint real | Waldir al cierre |
| Flakiness | N/D; requiere historia de repeticiones equivalentes | Eva tras ejecuciones comparables |
| p95 / error rate | Pendiente; no existe staging todavía | Waldir con TC-PERF-01 |
| Participación | Pendiente de cuentas, commits, PR y revisiones reales | Todos; matriz de evidencias |

Mejoras propuestas: integrar servidor con negativos de autorización (Gerardo, S1-S2), automatizar archivos y reporte de fallos UI (Eva, S2), carga/CSV y métricas por sprint (Waldir, S3), restauración/accesibilidad antes de release (todos, S4). Estas son metas, no resultados ya obtenidos.
