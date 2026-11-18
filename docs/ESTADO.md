# Estado real de Nido

## Actualización de integración · 18/11/2026

Este corte sustituye las afirmaciones temporales del apartado histórico de abajo. La fuente de estado de revisión y merge sigue siendo GitHub.

- HU-01..10 están integradas en `develop`; los PR de Eva #32, #33 y #34 y la corrección de escaneo #36 están fusionados. La integración en Git no demuestra que los componentes estén desplegados en nido-dev ni aceptados por el equipo.
- El rediseño y el incremento HU-11 de Waldir están en el PR #38, pendiente de cambios y revisión. Las tres comprobaciones de CI del head revisado pasaron, pero una prueba con dos conexiones sobre PostgreSQL local reprodujo una carrera entre la revocación de membresía y la modificación o eliminación de hojas; el detalle está en la revisión del PR.
- El 18/11, una consulta a la API del proyecto de pruebas sin datos de usuario devolvió `PGRST205` para `folders`, `documents` y `budget_sheets`. En el intento anterior se habían observado únicamente las siete migraciones identity/family; la aplicación de carpetas quedó interrumpida. No se ha acreditado que las tablas o las funciones de documentos estén desplegadas, ni que crear carpetas funcione en nido-dev.
- El escáner real, la purga física de archivos, la reconciliación de publicaciones interrumpidas (#37) y el presupuesto completo permanecen pendientes. Los archivos permanecen en cuarentena si no hay escáner operativo. No presentar el modo demo en memoria como persistencia o pruebas de Supabase.
- La revisión local del head `9c7da8f` del PR #38 ejecutó `flutter analyze` sin incidencias y 76 pruebas Flutter aprobadas. La reproducción de concurrencia usó PostgreSQL 18.6 con esquema reducido y datos ficticios, no la suite integral Supabase ni un dispositivo real. El servidor temporal se detuvo al terminar.

Detalle y límites: [evidencia de integración](../evidencias/OPS_20_20261118.md). Las verificaciones de dispositivo, despliegue remoto y aceptación deben registrarse por separado.

## Corte histórico · 14/11/2026

Control del 14/11/2026. Entrega objetivo: martes 17/11/2026. Producto único móvil Flutter + Supabase directo. Solo datos ficticios.

## Implementado por Gerardo, pendiente de revisión

G0 (#22) y HU-01..07 (#2..8): Auth con confirmación/recuperación PKCE, sesión en almacenamiento seguro, perfil privado e ID público, consentimiento por grupo, CRUD lógico de familias, invitaciones con búsqueda exacta limitada, administración/salida, parentescos sin ciclos y mascotas. Flutter usa repositorios/DTO/ViewModels y supabase_flutter 2.18.3. La demo en memoria se conserva únicamente con NIDO_DEMO=true.

En nido-dev están aplicadas siete migraciones identity/family y desplegada lookup-user. RLS/grants y RPC validan sesión Auth vigente, actor y grupo. El cliente no puede escribir directamente membresías ni el resto de tablas críticas. El guard consulta auth.sessions sin exponerla al móvil; no confunde logout con invalidación criptográfica de JWT.

## Verificación ejecutada

- PostgreSQL local: 150 aserciones pgTAP; Auth HTTP: 31 comprobaciones; familia/Edge HTTP: 48; handler Edge: 3 tests.
- Concurrencia: 3 escenarios de último admin y 2 de ciclos, con dos conexiones independientes y bloqueo observado.
- OPS: 45 tests Flutter PASS; análisis limpio; cobertura de dominio 88,81% y global 52,44%. Nueve tests Python de reportes/plan PASS.
- Backup/restauración PostgreSQL local PASS: owners/grants conservados; con rol authenticated, perfil propio visible y perfil ajeno oculto; familia/membresías/mascota restaurados. No acredita objetos Storage ni recuperación del proveedor.
- TECNO KN4 Android 16: escenario real PASS con 12 comprobaciones y tres capturas; confirma registro/recuperación PKCE desde Mailpit local, perfil, familia, invitación, parentesco, mascota, consentimiento y JWT anterior al logout sin filas privadas. Consultar evidencias/OPS_20.md; no acredita Storage/presupuesto ni iOS.
- Supabase remoto: redirect exacto nido://auth/callback, confirmación email, contraseña mínima 12 y cambio seguro de contraseña configurados; capturas en evidencias/ui.

## GitHub y equipo

Eva/pizzatoev y Waldir/riblawaldir aceptaron Write al repositorio. Las issues tienen asignados reales; ambos tienen acceso de edición al Project autorizado por Gerardo. PREP/G0/HU-01..07 están In review; OPS-01 preparado para revisión al publicar su PR. No hay firmas, aprobaciones ni release final inventados.

Los PR #21, #23..30 están apilados; Waldir tiene solicitudes reales de revisión y aprobaciones registradas en #21/#23..27 con límites. Las correcciones de sangre/autoinvitación/guard directo se entregan en OPS-01 y requieren revisar su diff. Seguir [INTEGRACION.md](INTEGRACION.md) para revisar, cambiar bases y fusionar en orden. Mantener las protecciones de develop/main.

## Pendiente antes de la entrega completa

Eva: carpetas, documentos, Storage privado, cuarentena/escaneo, pruebas de bytes y auditoría/herramientas. Waldir: presupuesto persistente, categorías/movimientos/totales/CSV, rendimiento y métricas. Gerardo integra sus módulos y revisa a Eva cuando exista su PR.

La cola cleanup_jobs está implementada, pero no su worker físico: el acceso lógico se retira; no se afirma que los objetos hayan sido purgados. Coordinar la limpieza de archivos con Eva antes de habilitarla. delete-account es contrato previsto, no función desplegada ni botón disponible. No se han creado buckets ni escáner como parte de identidad/familias.

Revisión docente de CU, inspección cruzada, aceptación humana, exploración/TalkBack/texto 200%, rendimiento, Storage/CSV y regresión conjunta pendientes. iOS no probado al no disponer de macOS/dispositivo. Firma de entrega, backup de objetos, ensayo de rollback y release/tag requieren integración y aceptación. Ver [índice](../evidencias/INDICE.md).
