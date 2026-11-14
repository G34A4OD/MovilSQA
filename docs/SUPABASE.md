# Supabase directo para la app móvil · ADR-002 vigente

**Stack confirmado por el usuario: Flutter + Supabase, sin servidor propio ni producto web.** Auth es la única fuente de cuentas/sesiones; PostgreSQL, RLS, RPC y Storage privado forman el backend administrado. La referencia anterior al stack de otro proyecto queda sustituida por esta decisión.

Estado real al 14/11/2026: nido-dev conectado por MCP; base de identidad/familia y guard de sesión aplicados con RLS. SDK 2.18.3 fijado e inicialización móvil con almacenamiento seguro en HU-01. Ver ESTADO.md, AUTH.md y supabase/LOCAL.md para resultados y pendientes; documentos/presupuesto todavía se implementan por sus responsables.

## Configuración del móvil

Instalados y fijados supabase_flutter 2.18.3 y flutter_secure_storage 11.2.0; pubspec.lock versionado. Main inicializa SDK/PKCE y almacenamiento seguro por proyecto. Los repositorios de identidad/familia ya consumen Auth/Data API/RPC.

El móvil recibe únicamente SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY de un proyecto de pruebas. Ambas son configuración de cliente, no contraseñas. La publishable key puede distribuirse con la app; no debe confundirse con una secret key. La configuración real de desarrollo se pasa por un archivo local ignorado o dart-define y los ejemplos versionados usan marcadores.

~~~dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
);
~~~

Ejemplo para la versión del SDK que se fije al implementar. La [referencia Flutter actual](https://supabase.com/docs/reference/dart/initializing) usa publishableKey y mantiene anonKey como parámetro anterior; comprobar la firma de la dependencia bloqueada. No introducir secret/service_role, contraseñas PostgreSQL, access tokens de CLI ni claves de firma en Flutter o Git.

## Auth y sesión

Registro con auth.signUp, verificación por correo, auth.signInWithPassword, recuperación con resetPasswordForEmail y actualización de contraseña en el flujo autenticado. Configurar deep links de verificación/recuperación para Android/iOS y redirect URLs del proyecto; no inventar un portal web para completar el login.

No almacenar CI, sangre, domicilio o salud en user_metadata ni claims JWT. Completar perfil en tablas protegidas; public_id se genera en DB, no desde metadata editable. No otorgar permisos de grupo a partir de un dato enviado durante signUp.

Persistir refresh/access tokens mediante un adaptador de almacenamiento seguro compatible con la versión elegida (Keychain/Keystore), sin suponer que el almacenamiento predeterminado ya lo hace. Al logout retirar datos/cachés del usuario y canales Realtime. Documentar scope local/global: la [referencia signOut](https://supabase.com/docs/reference/dart/auth-signout) actual usa local por defecto.

Un JWT emitido no queda invalidado instantáneamente solo por borrar el refresh token. Para accesos sensibles, implementar/probar el control restringido de sesión vigente descrito en SEGURIDAD.md; la expulsión del grupo sí debe afectar nuevas peticiones por consultar membresía viva en RLS. El guard de sesión y membresía está probado en identidad/familia mediante SQL y JWT reales locales; Storage y presupuesto deben probar sus capas por separado.

## Esquemas, grants y RLS

1. Crear migraciones SQL en supabase/migrations con timestamp único. Public contiene las tablas de aplicación expuestas al SDK y private los helpers/auditoría internos no expuestos.
2. Activar RLS en **cada tabla expuesta**, revocar todos los permisos de anon salvo los estrictamente necesarios (en este producto no hay datos familiares públicos) y otorgar a authenticated solo operaciones autorizadas.
3. Policies USING y WITH CHECK usan auth.uid(), propietario y membresía activa. No depender del filtro family_id en Flutter, ni de claims de admin familiares que queden desactualizados.
4. Private_profiles solo titular; profiles solo datos mínimos; profile_shares limita el contenido compartido por consentimiento. Las vistas deben respetar RLS con security_invoker o evitar exponerlas.
5. Revocar DML directo de membresías y demás escrituras críticas. Conceder EXECUTE solo a RPC necesarias. SECURITY DEFINER exige search_path seguro, autorización interna y auditoría; una función publicada por defecto puede sobrepasar RLS.
6. Probar con clientes reales anon/authenticated y cuentas A/B/C, no solo con Dashboard o service_role, que sobrepasan las políticas.

Fuentes primarias: [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) y [funciones y privilegios](https://supabase.com/docs/guides/database/functions). Los helpers y policies de identidad/familia están desplegados; los de documentos y presupuesto siguen a cargo de sus módulos.

## Archivos privados

Dos buckets privados: nido-quarantine y nido-documents, máximo 10 MiB y tipos PDF/JPG/PNG. El cliente solo inserta en una ruta de cuarentena reservada por begin_document_upload y perteneciente al usuario; no sobrescribe ni publica por sí mismo. El servicio confiable valida tamaño/contenido/firma, ejecuta escaneo y promueve el objeto aprobado. Si falta escáner, no aprobar archivos; dejar explícito el bloqueo.

Las políticas SELECT de storage.objects comprueban documento approved, grupo vigente y consentimiento. Usar storage.from('nido-documents').download(path) con la sesión del usuario; no getPublicUrl ni createSignedUrl para compartir documentos familiares. Una URL firmada emitida puede reutilizarse hasta expirar. Ver [buckets privados](https://supabase.com/docs/guides/storage/buckets/fundamentals) y [download Flutter](https://supabase.com/docs/reference/dart/storage-from-download).

Impedir firmar URLs no puede depender de que la UI oculte ese método: SELECT sirve a varias operaciones Storage. La policy debe limitarse a lecturas autenticadas mediante storage.allow_any_operation con object.get_authenticated y object.get_authenticated_info, además de los checks de sesión/documento/grupo. No otorgar operaciones de firma, listado general ni rutas alternativas por otra policy permisiva. Verificar los [helpers por operación](https://supabase.com/docs/guides/storage/schema/helper-functions) en la versión desplegada y probar createSignedUrl con un cliente modificado: debe fallar. Si el proyecto no soporta esa separación, negar SELECT Storage al móvil y usar una Edge de lectura autenticada que autorice metadata y devuelva bytes, nunca una URL firmada.

La app no conserva documentos sensibles en caché persistente sin control; limpia buffers/cachés al salir, cambiar usuario o perder acceso. Una exportación o copia deliberadamente descargada queda fuera de la revocación. Configurar/validar cacheControl del objeto y probar revocación con una nueva petición autenticada; la prueba no puede basarse en una imagen servida desde caché local.

## Funciones Edge y secretos

lookup-user valida JWT, membresía admin y rate limit, devuelve solo coincidencia exacta de public_id. process-document ejecuta validación/escaneo y transición de estado. delete-account realiza tareas Auth Admin después de reautenticación y comprobación de pertenencias/último admin. No son un reemplazo de RPC para transacciones de varias filas.

Dentro de una Edge Function, propagar el JWT del usuario a operaciones sujetas a RLS. Un cliente elevado con secret/service_role solo se usa para el paso privilegiado inevitable después de autorización explícita; no transforma cada petición en acceso ilimitado. Credenciales solo en secretos de Supabase/CI localmente configurados.

## Preparación y pruebas

Gerardo: Auth/deep links, configuración compartida, esquema base y family RPC/RLS. Eva: Storage, documents RPC/RLS y escaneo. Waldir: tablas/RPC/RLS financieras y exportación móvil. Cada módulo conserva su migración y tests propios, con integración coordinada.

Antes de usar datos reales: Supabase de pruebas con datos ficticios, migraciones reproducibles, tests SQL/pgTAP de permisos e invariantes, dos peticiones concurrentes para último admin, integración móvil Auth/DB/Storage y backup/restauración. El CI cubre Flutter/reportes, SQL, Auth/Edge/familia HTTP y concurrencia. OPS agrega compilación Android; pruebas reales de dispositivo y restauración se registran por separado. Storage y presupuesto requieren integración.

Verificar qué incluye el plan de Supabase antes de depender de backups, límites de sesión o recuperación. Respaldo de DB no equivale automáticamente a respaldo de objetos Storage. No se contrataron servicios ni se aplicaron recursos por preparar esta guía.
