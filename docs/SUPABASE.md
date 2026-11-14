# Supabase con el stack del curso · ADR-002

Elección del usuario: preparar Supabase. Restricción docente XP p. 20: Flutter + Laravel + PostgreSQL; la p. 56 menciona **Supabase como hosting de PostgreSQL**. Se combinan: Supabase aloja PostgreSQL y Storage privado; **Flutter consume exclusivamente API Laravel**, que controla identidad, pertenencia y transacciones. Se usa Sanctum para sesiones móviles, sin dos sistemas de cuentas ni contraseñas sincronizadas. La propuesta está preparada localmente; no hay proyecto Supabase provisionado o conectado todavía.

## Frontera de confianza

1. Datos de Nido en esquema PostgreSQL `nido`, fuera de los esquemas expuestos por la Data API. Revocar permisos anon/authenticated/PUBLIC sobre ese esquema; comprobarlo desde REST anónimo.
2. Laravel se conecta por SSL con rol propio de mínimo privilegio; migraciones con credencial separada. No usar usuario postgres propietario como runtime. Configurar search_path y validación de certificado según el entorno real.
3. Buckets privados `nido-quarantine` y `nido-documents`; sin policies de acceso público. Solo el servidor tiene la credencial que permite operar Storage; este secreto puede sobrepasar RLS, por eso cada acceso pasa por Policy de Laravel.
4. Flutter no recibe claves service_role/secret ni credenciales de DB. No instalar supabase_flutter para hacer consultas paralelas que evadan Laravel. Solo base URL pública y token de sesión Sanctum almacenado de forma segura.
5. Servidor valida/scanea el archivo en cuarentena y transmite contenido autorizado; no emitir enlaces permanentes de Storage. Purga física reintentable y auditoría sin contenido sensible.

La documentación oficial explica [conexión PostgreSQL desde servidor](https://supabase.com/docs/guides/database/connecting-to-postgres) y [control de acceso Storage](https://supabase.com/docs/guides/storage/security/access-control). Los accesos directos desde Flutter con anon/authenticated deben fallar por diseño. RLS no sustituye las Policies Laravel cuando el servidor usa credenciales privilegiadas.

## Preparación con Gerardo

- Crear o elegir un proyecto Supabase **de pruebas** con datos ficticios y la región acordada. URL/project ref son identificadores públicos; contraseñas/secret keys solo en `.env` local o secretos de hosting/CI.
- Revisar `web/.env.example`, crear `.env` local y comprobar SSL, rol runtime y esquema no expuesto. No subir archivos de entorno reales.
- Crear buckets privados, límite 10 MiB y MIME PDF/JPG/PNG. Mantener cuarentena hasta escáner operativo.
- Ejecutar migraciones Laravel sobre esquema de pruebas. Guardar versiones/locks; no escribir migraciones de documentos y presupuesto en el mismo archivo.
- Probar API con cuentas de aplicación A/B y no miembro; probar también acceso Supabase REST/Storage sin sesión/anon para confirmar que no hay una ruta alternativa abierta.
- Backup/restauración: comprobar qué incluye el plan contratado y respaldar objetos Storage además de DB. No asumir backups o recuperación automática del plan gratuito.

## Tests obligatorios al conectar

TC-SEC-01..04 y TC-DOC-03/04, TC-FAM-04 concurrente en PostgreSQL, categoría usada y CSV. Guardar respuesta sin bytes sensibles, entorno/project ref de pruebas y commit. Un dashboard con tablas creadas no demuestra autorización correcta.
