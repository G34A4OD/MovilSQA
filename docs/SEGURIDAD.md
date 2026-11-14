# Seguridad y privacidad por diseño

Estado: controles exigidos para implementación; la demo local no certifica ninguno de los controles del servidor.

| Riesgo | Control requerido | Evidencia / dueño |
|---|---|---|
| Acceso por ID ajeno (BOLA/IDOR) | Policies por membresía activa y propietario en cada endpoint; nunca confiar en group_id del cliente | TC-SEC-01..04, Gerardo y revisor |
| Buscar CI/datos de salud | ID público aleatorio no secuencial, coincidencia exacta, rate limit; respuesta mínima sin CI/domicilio | TC-FAM-02, Gerardo |
| Contraseñas/tokens | Hash de contraseña con mecanismo Laravel; Sanctum con caducidad/revocación, tokens en Keychain/Keystore mediante almacenamiento seguro | TC-AUTH-01..03, Gerardo |
| Último admin/concurrencia | Transacción y bloqueo del grupo; restricción y prueba de dos peticiones concurrentes en PostgreSQL real | TC-FAM-04, Gerardo |
| Salud y documentos | Consentimiento por grupo; almacenamiento privado cifrado en reposo; descarga por controlador autenticado con `Cache-Control: no-store` | TC-DOC-03/04, Eva |
| Archivo malicioso | JPG/PNG/PDF, máx. 10 MiB, MIME y firma reales; UUID como nombre; cuarentena y escáner; sin SVG/HTML ni ejecución | TC-DOC-02, Eva |
| Fuga al salir del grupo | Revalidar membresía en cada acceso; no enlaces públicos ni URLs largas reutilizables; purgar cachés locales | TC-SEC-02, todos |
| Fuga entre familias | Consultas con alcance explícito y tests con A/B/usuario multigrupo | TC-SEC-01, todos |
| Escalado de admin | FormRequest con lista permitida, evitar mass assignment de is_admin/user_id; solo Action autorizada | TC-FAM-03, Gerardo |
| Finanzas ajenas | Propietario de hoja + pertenencia activa, admin no sobrepasa propiedad | TC-BUD-05, Waldir |
| CSV injection | Neutralizar celdas de texto cuyo primer carácter significativo sea = + - @ o control, RFC4180, descarga explícita | TC-BUD-04, Waldir |
| Fuga en logs/evidencia | Redactar Authorization, CI, domicilio, salud, contenido de PDFs y capturas; solo datos sintéticos | Inspección QA, Eva |
| Pérdida de información | Backups cifrados, retención propuesta 30 días, restauración probada en staging | TC-OPS-01, Gerardo |

## Despliegue y operación

Solo HTTPS en staging/producción; servidor con `APP_DEBUG=false`, CORS explícito, secretos en variables/gestor, mínimos privilegios PostgreSQL y bucket privado. No subir `.env`, APP_KEY, contraseñas, tokens, service keys, keystores ni documentos reales. `.env.example` contiene nombres y valores ficticios. La app solo contiene base URL pública; jamás credenciales de PostgreSQL.

Laravel Sanctum proporciona [tokens para API móvil](https://laravel.com/docs/13.x/sanctum). Implementar logout en servidor y borrado local incluso ante error de red. Reautenticación al borrar cuenta o grupo. No desactivar TLS ni usar hashes de contraseña creados en el cliente. No afirmar cifrado de extremo a extremo: el servidor debe procesar y autorizar los archivos.

Usar [discos privados de Laravel](https://laravel.com/docs/13.x/filesystem); nunca `storage:link` para documentos familiares. Una URL firmada ya emitida puede seguir válida hasta vencer; se prefiere streaming autorizado en cada petición para revocación inmediata. Descargas deliberadas al teléfono salen del control de revocación; informar al usuario antes de guardar/exportar.

## Datos personales y ciclo de vida

La cuenta y el perfil son del titular; compartir en cada grupo es una acción explícita. Perfil visible en listados: nombre de presentación e ID público; el resto requiere consentimiento específico. Registrar quién compartió qué y con qué grupo, sin copiar contenido sensible al log. Retirar/borrar debe eliminar referencia y programar limpieza física verificable. Retención, consentimiento de menores y obligaciones locales requieren validación antes de usar datos reales; no se declara cumplimiento legal sin revisión.

## Pruebas negativas mínimas

Dos grupos A/B, dos admins en A, último admin en B, miembro normal, no miembro, usuario expulsado, invitado pendiente y sesión revocada. Ejecutar GET/POST/PATCH/DELETE y descarga con IDs de otro grupo y de otra hoja. Exigir 401/403/404 sin campos ni bytes sensibles. Repetir tras logout, expulsión y cambio del grupo activo. Los permisos del dominio Dart se verifican como UX; las pruebas de API deben repetirse contra el servidor real.
