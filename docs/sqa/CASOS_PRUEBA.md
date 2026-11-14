# Catálogo de pruebas

Estado inicial: diseñado. Solo se marca ejecutado si existe reporte de la ejecución. IDs se repiten en nombres de pruebas automatizadas y matriz. Precondición general: datos ficticios; cuentas A (admin), B (miembro), C (ajeno), grupos G1/G2 y servidor/cliente identificados. Reiniciar fixtures por test.

| TC / HU | Prioridad y técnica | Pasos / datos | Resultado esperado |
|---|---|---|---|
| TC-AUTH-01 / HU-01 | P0, equivalencias | Registrar email válido, duplicado y contraseña inválida; login correcto/incorrecto | Validación sin enumeración, hash, token solo en éxito |
| TC-AUTH-02 / HU-02 | P1, límites | Perfil vacío, nacimiento futuro, 29/02 válido/inválido, sangre desconocida | Rechazo de fechas inválidas; ID único inmutable; campos privados |
| TC-AUTH-03 / HU-01 | P0, transición | Logout/revocar y reutilizar token; recuperar contraseña | Token revocado 401; reset un solo uso |
| TC-FAM-01 / HU-03 | P0, decisiones | Crear grupo, intentar crear/renombrar/borrar como miembro/ajeno | Creador admin; cambios solo admin; CRUD aislado |
| TC-FAM-02 / HU-04 | P0, estados | Invitar, repetir, aceptar como tercero, rechazar, aceptar de nuevo, vencer | Sin acceso pendiente; solo receptor; sin duplicados; vencida denegada |
| TC-FAM-03 / HU-05 | P0, decisiones | Miembro intenta promoverse; admin promueve otro; renuncia y salida | Sin escalado; permisos actualizados; no fuga a otro grupo |
| TC-FAM-04 / HU-05 | P0, concurrencia | Último admin sale/se degrada; dos admins salen simultáneamente | Bloqueo sin cambios parciales; siempre queda un admin |
| TC-FAM-05 / HU-06 | P1, grafo | A->B, B->C y luego C->A; A->A; miembro de otro grupo | Rechazar ciclos/autorrelación/ajenos; árbol consistente |
| TC-FAM-06 / HU-07 | P1, decisiones | CRUD mascota como admin y normal; abrir tarjeta | Solo admin escribe; sin cuenta; ficha independiente |
| TC-DOC-01 / HU-08 | P1, equivalencias | Crear/renombrar/borrar carpeta propia, vacía y ajena | Nombre válido; no rutas; titular correcto; confirmar cascada |
| TC-DOC-02 / HU-09 | P0, límites | PDF/JPG/PNG, HTML renombrado, 0/1/10MiB/10MiB+1, malicioso sintético | Firma/MIME/tamaño validados en servidor; cuarentena/escaneo |
| TC-DOC-03 / HU-09,10 | P0, autorización | Compartir con G1; leer desde G1/G2; modificar como otro miembro | Solo G1 lee; titular escribe y admin modera auditado |
| TC-DOC-04 / HU-09 | P0, revocación | Descargar; expulsar/salir; repetir misma URL | Acceso posterior denegado; sin URL pública/cache con bytes |
| TC-BUD-01 / HU-13 | P0, límites | Montos 0/-1/0.01/máximo/máximo+0.01/NaN/1e3; mes 0/1/12/13; año 0/1/9999/10000 | Solo entradas válidas; sin redondeo ni mutación inválida |
| TC-BUD-02 / HU-13,14 | P0, oráculo | Enero ingreso 150, egreso175; diciembre30; otro año9000. Editar/borrar | Enero -25, anual +5, año ajeno excluido; recálculo exacto |
| TC-BUD-03 / HU-12 | P1, estado | Crear/editar categoría; borrar/cambiar tipo con uso, sin uso | Bloquear si usada; nombres/descripción guardados |
| TC-BUD-04 / HU-15 | P0, datos adversos | Exportar año vacío/con movimientos, comillas/comas/saltos, =/+/-/@ y control | CSV UTF-8 válido, 12 meses, totales, texto neutralizado, descarga real |
| TC-BUD-05 / HU-11 | P0, BOLA | CRUD hoja propia y ajena, admin ajeno, grupo abandonado | Dueño+miembro activo solamente; no inferir finanzas ajenas |
| TC-SEC-01 / HU-03,08,11 | P0, decisiones | Sustituir cada ID por objeto de G2 en GET/POST/PATCH/DELETE | 403/404 sin contenido; no efectos secundarios |
| TC-SEC-02 / HU-05 | P0, estados | Invitado/expulsado/token revocado intenta leer API/archivos | No accede; no caché residual en UI |
| TC-SEC-03 / HU-02 | P0, exposición | Buscar ID y revisar respuesta/logs/capturas | Sin CI, domicilio, salud ni token |
| TC-SEC-04 / HU-09 | P0, mass assignment | Modificar owner_id/family_id/is_admin y ruta de archivo | Campos ignorados/rechazados, sin reasignación |
| TC-UI-01 / HU-03,14 | P1, widget | Abrir demo, navegar, cambiar año y crear movimiento | Sin excepción; totales correctos y estado en memoria |
| TC-UI-02 / transversal | P1, manual | TalkBack, 200% texto, 360dp, teclado, landscape | Controles accesibles, sin cortes ni pérdida de formulario |
| TC-MOB-01 / transversal | P1, sistema | Perder red/reintentar/doble toque/segundo plano | Error recuperable; no duplicar escrituras |
| TC-PERF-01 / RNF-04 | P1, carga | 20 usuarios, 1.000 movimientos/hoja, staging y 5 min medidos | p95<800ms, errores<1%; registrar entorno/datos |
| TC-OPS-01 / RNF-06 | P1, recuperación | Backup cifrado y restauración en DB de pruebas | Integridad/cuentas/archivos recuperados; RPO/RTO medidos |

Capturar fallos UI en el instante del fallo, junto con stack y request_id. No usar captura de demo como prueba de autorización del servidor. Registrar criterio humano y firma en `evidencias/plantillas/REVISION.md`.
