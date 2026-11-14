# Reporte automatizado · Nido

Resultado global: **PASS**. Alcance: unidad/widget de la base local; no API ni E2E móvil.

- Ejecución: ops-20-final
- Inicio UTC: 2026-11-14T23:28:33.4960552Z
- Commit base: 05973fd9ec80212041cd2a4e4f051b751d3a8103; árbol con cambios: True
- SHA-256 de fuentes normalizadas a LF: 183dee7a0b5d10548fad6c62aeb80466ee969a643158b54d11e54bd4c2538cbc
- Entorno: Microsoft Windows NT 10.0.26200.0; Flutter: Flutter 3.41.9 • channel stable • https://github.com/flutter/flutter.git
- Duración suite: 20.315 s
- Pub/formato/análisis/tests (exit): 0/0/0/0

| Total | Pasados | Fallidos/incompletos | Saltados | Tasa éxito (sin saltados) |
|---:|---:|---:|---:|---:|
| 45 | 45 | 0 | 0 | 100.00% |

Cobertura total instrumentada: 1053/2008 = 52.44%.
Cobertura de dominio y dinero: 246/277 = 88.81%. No es cobertura de requisitos ni de servidor.

## Detalle y trazabilidad

| Caso | TC | HU | Resultado |
|---|---|---|---|
| TC-SEC-01: HTTP solo loopback de pruebas con bandera explícita y build debug | TC-SEC-01 |  | success |
| TC-SEC-01: solo configuración pública HTTPS, sin credenciales de servidor | TC-SEC-01 |  | success |
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
| TC-FAM-04 HU-05: último admin explica bloqueo y conserva selección | TC-FAM-04 | HU-05 | success |
| TC-FAM-01 HU-03: reintento conserva request_id y pérdida de acceso vacía selección | TC-FAM-01 | HU-03 | success |
| TC-FAM-01 HU-03: paginación devuelve más de 100 familias sin omisiones | TC-FAM-01 | HU-03 | success |
| TC-AUTH-04 TC-SEC-03: logout elimina rutas y datos de la familia abierta | TC-AUTH-04, TC-SEC-03 |  | success |
| TC-FAM-03 HU-04: invitación recibida se acepta desde pantalla y refresca grupos | TC-FAM-03 | HU-04 | success |
| TC-FAM-06 HU-07: fecha opcional y límites, sin identidad humana | TC-FAM-06 | HU-07 | success |
| TC-FAM-06 HU-07: reintento estable y CRUD conserva versión esperada | TC-FAM-06 | HU-07 | success |
| TC-FAM-06 HU-07: miembro ve ficha separada y no acciones de admin | TC-FAM-06 | HU-07 | success |
| TC-FAM-05 HU-06: hijo/nieto/sobrino invierten dirección, parentesco no concede admin | TC-FAM-05 | HU-06 | success |
| TC-FAM-05 HU-06: generaciones, abuelo explícito y ciclo defensivo | TC-FAM-05 | HU-06 | success |
| TC-FAM-05 HU-06: reintento no cambia request y conflicto conserva grafo | TC-FAM-05 | HU-06 | success |
| TC-FAM-05 HU-06: árbol renderiza tres generaciones sin desbordar | TC-FAM-05 | HU-06 | success |
| TC-FAM-02 HU-04: ID incompleto no busca; editar lo buscado retira candidato | TC-FAM-02 | HU-04 | success |
| TC-FAM-02/03 HU-04: reintentos conservan request, éxito actualiza pendientes | TC-FAM-02 | HU-04 | success |
| TC-AUTH-01/04 HU-01: formulario limpia contraseña y gate elimina cuenta al salir | TC-AUTH-01 | HU-01 | success |
| TC-PRO-01 HU-02: fecha imposible y futuro rechazados antes de enviar | TC-PRO-01 | HU-02 | success |
| TC-PRO-01 HU-02: creación, versión y conflicto no sustituyen datos locales | TC-PRO-01 | HU-02 | success |
| TC-PRO-01 HU-02: validación no llama al repositorio | TC-PRO-01 | HU-02 | success |
| TC-UI-01 HU-14 navegar y agregar monto exacto en demo | TC-UI-01 | HU-14 | success |
| TC-AUTH-01 HU-01: alta exige contraseña fuerte y no presupone sesión | TC-AUTH-01 | HU-01 | success |
| TC-AUTH-02 HU-01: error genérico no filtra respuesta interna | TC-AUTH-02 | HU-01 | success |
| TC-AUTH-01 HU-01: datos inválidos y doble envío no generan llamadas duplicadas | TC-AUTH-01 | HU-01 | success |
| TC-AUTH-03 HU-01: recuperación no confirma existencia de cuenta | TC-AUTH-03 | HU-01 | success |
| TC-AUTH-03 HU-01: enlace de recuperación exige nueva contraseña y limpia estado | TC-AUTH-03 | HU-01 | success |
| TC-AUTH-04 HU-01: logout fallido no finge revocación remota | TC-AUTH-04 | HU-01 | success |
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
