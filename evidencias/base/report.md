# Reporte automatizado · Nido

Resultado global: **PASS**. Alcance: unidad/widget de la base local; no API ni E2E móvil.

- Ejecución: base-final-01
- Inicio UTC: 2026-11-14T05:09:28.2768425Z
- Commit base: afaa69be5e9e775e8832132d0fc8e68bf48ded70; árbol con cambios: True
- SHA-256 de fuentes normalizadas a LF: b78e924454dd4db4c8aa28f56c25232ec7e2e529c092dc0b77b66e41445ba41f
- Entorno: Microsoft Windows NT 10.0.26200.0; Flutter: Flutter 3.41.9 • channel stable • https://github.com/flutter/flutter.git
- Duración suite: 8.348 s
- Pub/formato/análisis/tests (exit): 0/0/0/0

| Total | Pasados | Fallidos/incompletos | Saltados | Tasa éxito (sin saltados) |
|---:|---:|---:|---:|---:|
| 19 | 19 | 0 | 0 | 100.00% |

Cobertura total instrumentada: 380/572 = 66.43%.
Cobertura de dominio y dinero: 169/181 = 93.37%. No es cobertura de requisitos ni de servidor.

## Detalle y trazabilidad

| Caso | TC | HU | Resultado |
|---|---|---|---|
| TC-BUD-02 HU-14 suma mensual/anual y separa años | TC-BUD-02 | HU-14 | success |
| TC-BUD-02 HU-13 editar y eliminar recalcula sin duplicados | TC-BUD-02 | HU-13 | success |
| TC-BUD-03 HU-12 categoría usada no cambia tipo ni se elimina | TC-BUD-03 | HU-12 | success |
| TC-BUD-01 HU-13 límites de mes/año/monto y categoría ajena | TC-BUD-01 | HU-13 | success |
| TC-BUD-04 HU-15 CSV con doce meses, totales y fórmulas neutralizadas | TC-BUD-04 | HU-15 | success |
| TC-BUD-03 HU-12 nombre de categoría vacío rechazado | TC-BUD-03 | HU-12 | success |
| TC-DOC-02 HU-09 valida firma y tamaño de PDF/JPG/PNG | TC-DOC-02 | HU-09 | success |
| TC-DOC-01 HU-08 nombre obligatorio y sin ruta proporcionada | TC-DOC-01 | HU-08 | success |
| TC-FAM-01 HU-03 creador admin y solo admin invita | TC-FAM-01 | HU-03 | success |
| TC-FAM-02 HU-04 invitación no concede acceso; receptor decide una vez | TC-FAM-02 | HU-04 | success |
| TC-FAM-02 HU-04 rechazo y duplicado pendiente | TC-FAM-02 | HU-04 | success |
| TC-FAM-04 HU-05 último admin no sale ni renuncia | TC-FAM-04 | HU-05 | success |
| TC-FAM-03 HU-05 transferencia, renuncia y salida | TC-FAM-03 | HU-05 | success |
| TC-FAM-05 HU-06 ascendencia rechaza ciclos, autorrelación y ajenos | TC-FAM-05 | HU-06 | success |
| TC-SEC-01 HU-03 mismo usuario en dos grupos sin compartir permisos | TC-SEC-01 | HU-03 | success |
| TC-BUD-01 HU-13 decimal exacto y coma local | TC-BUD-01 | HU-13 | success |
| TC-BUD-01 HU-13 rechaza montos ambiguos y fuera de límite | TC-BUD-01 | HU-13 | success |
| TC-UI-01 HU-14 navegar y agregar monto exacto en demo | TC-UI-01 | HU-14 | success |
| TC-UI-01 HU-13 monto inválido conserva formulario | TC-UI-01 | HU-13 | success |

## Fallos y evidencia

Logs: tests.jsonl, analyze.log, pub.log y format.log. Cobertura: lcov.info. Resultado JUnit: junit.xml.
Errores de carga/compilación bloquean aunque no haya casos iniciados.
Capturas UI/dispositivo: no generadas por esta suite; adjuntar desde el ejecutor E2E al realizar esas pruebas.

## Observaciones y conclusiones

Verde valida solo los casos enumerados. Persistencia, permisos de servidor, dispositivo, carga y revisión humana permanecen pendientes.
Si falla: clasificar código/test/entorno, vincular bug, corregir y reejecutar conservando evidencia.
Flakiness, densidad de defectos y velocidad: N/D sin histórico/denominador/aceptación de sprint.

Elaboración: ejecución automatizada. Revisor independiente y aceptación PO: pendientes de validación real.
