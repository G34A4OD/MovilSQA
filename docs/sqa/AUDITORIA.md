# Auditoría interna inicial · AUD-01

Fecha: 14/11/2026. Tipo: revisión inicial de preparación, **no aprobación final ni auditoría independiente firmada**. Alcance: material recibido, estructura local y controles preparados. Auditor cruzado de cierre: pendiente de sesión real del equipo. Método: inspección de artefactos y ejecución automatizada documentada por separado.

| Hallazgo | Evidencia observada | Severidad / acción correctiva | Dueño / criterio de cierre |
|---|---|---|---|
| AUD-01-01 Falta Test Plan propio previo | Solo enunciado PDF y app contador inicial | Media: reconstruir línea base transparente y TP ágil | Eva; revisión/aceptación del equipo |
| AUD-01-02 No hay backend/controles de acceso | App inicial sin datos persistentes | Alta: Auth, RLS/grants mínimos, Storage privado, RPC transaccionales y negativos Supabase | Gerardo + módulos; TC-SEC y TC-FAM-04 concurrente pasan |
| AUD-01-03 Sin evidencia de tres participantes aún | Repositorio remoto solo README al iniciar | Media: invitar, issues, PR y revisión con cuentas reales | Todos; matriz de participación con enlaces |
| AUD-01-04 GH CLI sin autenticación al inicio | `gh auth status` sin sesión | Media: login del propietario, después bootstrap | Gerardo; issues/ramas/checks visibles |
| AUD-01-05 No hay prueba en dispositivo ni iOS | Starter sin suite de sistema | Alta para release: Android temprano, iOS cuando exista macOS | Eva; reporte con dispositivo/build/captura real |
| AUD-01-06 Falta calendario confirmado y Planner | Sin fecha de entrega suministrada | Media: estimación relativa y fechas al confirmar | Waldir; Planner con CPM y responsables |
| AUD-01-07 La demo en memoria no protege datos reales | Aviso explícito en UI/README y sin backend | Alta para uso real: mantener datos sintéticos hasta controles verificados | Todos; pruebas RLS/RPC/Storage y operación aprobadas |

Ningún hallazgo se cierra solo por este documento. La implementación base y reportes pueden resolver parcialmente la falta de tests; adjuntar ejecución y revisión independiente. Al cerrar: anotar PR/commit, test repetido, resultado, quién verificó y fecha. Auditoría por sprint añade hallazgos nuevos y acciones; evitar reemplazar el historial.

Conclusión de preparación: hay material para iniciar un trabajo trazable, pero la app final no está lista para manejar información familiar real. Decisión de release actual: **no apto como producto final**. Firmas de elaboración/revisión/PO: pendientes.

Actualización de alcance: el usuario confirmó Flutter + Supabase directo para este proyecto móvil. Se corrigen las acciones propuestas a esa arquitectura sin alterar los hechos observados ni cerrar hallazgos por documentación. Auth/RLS/RPC/Storage, escaneo y las suites Supabase siguen pendientes de implementación/verificación. No se certifica que logout invalide de inmediato un JWT ya emitido; la revocación de pertenencia se debe comprobar en nuevas operaciones RLS.
