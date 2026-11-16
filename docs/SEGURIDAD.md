# Seguridad y privacidad con Supabase directo

Estado: requisitos para implementar y probar. La demo local no certifica Auth, RLS, RPC, Storage ni seguridad de datos reales.

| Riesgo | Control requerido | Evidencia / dueño |
|---|---|---|
| IDs ajenos / BOLA | Grants mínimos + RLS USING/WITH CHECK por auth.uid(), propietario y membresía activa; no confiar en filtro Flutter | TC-SEC-01..04, Gerardo y revisor |
| CI/salud en listados | profiles mínimo, private_profiles solo titular, profile_shares por consentimiento y grupo | TC-AUTH-02 / TC-SEC-03, Gerardo |
| Enumeración de usuarios | Búsqueda public_id exacta mediante Edge con JWT, admin y rate limit; sin listado global | TC-FAM-02, Gerardo |
| Contraseñas y sesión | Supabase Auth; no gestionar hashes propios ni guardar contraseña; sesión en almacenamiento seguro | TC-AUTH-01..03, Gerardo |
| JWT tras logout | Limpiar sesión/cachés; reconocer vigencia residual del JWT y comprobar sesión viva en accesos sensibles | TC-AUTH-03 / TC-SEC-02, Gerardo |
| Último admin concurrente | RPC única con lock del grupo, autorización y conteo; revocar DML directo de memberships | TC-FAM-04 concurrente, Gerardo |
| RPC con privilegios excesivos | INVOKER preferido; DEFINER solo justificado, search_path vacío, esquemas explícitos, auth.uid y EXECUTE restringido | SQL/pgTAP y revisión, dueño del módulo |
| Archivos maliciosos | 10 MiB, PDF/JPG/PNG, MIME/firma/contenido en servicio confiable, cuarentena y escáner antes de approved | TC-DOC-02, Eva |
| Lectura de documentos ajenos | Bucket privado, policies storage.objects ligadas a metadata approved y grupo vigente | TC-DOC-03/04, Eva |
| Salida/expulsión | RLS consulta membresía actual en cada petición; sin URLs públicas/firmadas duraderas; purga local | TC-SEC-02 / TC-DOC-04, todos |
| Finanzas ajenas | Dueño de hoja + miembro activo; admin del grupo no hereda acceso a hojas ajenas | TC-BUD-05, Waldir |
| Categoría inválida / corrupción | FK/checks y RPC transaccional; sin DML alternativo que salte las reglas | TC-BUD-01..03, Waldir |
| CSV injection | Texto neutralizado y RFC4180; guardar/exportar es acción explícita | TC-BUD-04, Waldir |
| Fuga de secretos o evidencias | Solo publishable key en móvil; tokens y claves elevadas redactados; datos ficticios | Inspección de PR/artefactos, Eva |
| Pérdida de datos | Backup DB y objetos, retención propuesta 30 días y ensayo de restauración | TC-OPS-01, Gerardo |

## Frontera de confianza y privilegios

Flutter es un cliente no confiable. Un usuario puede llamar la Data API, RPC o Storage sin pasar por los widgets. Por eso la seguridad está en PostgreSQL/Storage/funciones, no en comprobar el rol Dart. Publishable key es configuración pública; secret/service_role y credenciales PostgreSQL nunca se distribuyen.

Activar RLS desde la creación de cada tabla expuesta; no usar una policy true como puente de integración. Revocar grants innecesarios de anon/authenticated. Las tablas sensibles se separan porque RLS decide acceso a filas, no qué campos deberían ser privados. Views y RPC no deben abrir una ruta alternativa que ignore RLS.

En una RPC privilegiada: obtener el actor de auth.uid(), rechazar sesión ausente, validar alcance del recurso en DB, bloquear filas en orden estable y ejecutar todo atómicamente. Revocar ejecución a PUBLIC/anon, conceder firmas necesarias a authenticated y restringir función/rol de mantenimiento. En helpers privados usados por policies, conceder solo permisos necesarios para la evaluación sin exponer el esquema private por Data API. [Guía oficial de funciones](https://supabase.com/docs/guides/database/functions).

## Sesión, logout y revocación

Supabase Auth utiliza JWT y refresh tokens. Cerrar sesión termina la sesión/refresh correspondiente, pero un JWT copiado puede seguir pasando validación criptográfica hasta su expiración. No prometer revocación instantánea por llamar signOut. La configuración de duración/scope debe quedar documentada y probada. [Sesiones oficiales](https://supabase.com/docs/guides/auth/sessions).

Para los datos sensibles de Nido se requiere implementar un helper privado restringido, por ejemplo has_live_session(), que contraste el claim session_id con auth.sessions y lo incorpore en las policies/RPC sensibles y Storage. No conceder lectura directa de auth.sessions al cliente. Verificar la semántica elegida y sus límites mediante pruebas; el simple diseño de este helper no prueba su funcionamiento.

Las autorizaciones familiares se consultan en memberships vigente, no solo en JWT: al salir/ser expulsado, las nuevas peticiones autenticadas pierden acceso al grupo aunque el token aún no haya expirado. Una respuesta en vuelo o bytes guardados anteriormente no se pueden borrar remotamente; no afirmar lo contrario.

## Flujo documental

El cliente reserva metadata en RPC y sube a nido-quarantine bajo una ruta opaca autorizada y sin upsert. No puede escribir status=approved ni mover el objeto al bucket final. El proceso confiable verifica contenido/tamaño/MIME/firma, escanea y publica en nido-documents privado. Sin servicio de escaneo operativo, el documento permanece en cuarentena.

La lectura usa download autenticado, con SELECT policy sobre storage.objects que consulta documento approved y membresía activa. No usar getPublicUrl ni URLs firmadas compartibles de larga duración. Configurar caché mínima, probar una nueva solicitud contra Storage tras revocación y eliminar cachés/buffers locales al cambiar sesión/grupo. La [documentación de buckets privados](https://supabase.com/docs/guides/storage/buckets/fundamentals) distingue descarga JWT/RLS y URL firmada con vencimiento.

SELECT Storage también puede autorizar otros métodos: restringir la policy mediante storage.allow_any_operation a object.get_authenticated y object.get_authenticated_info. No abrir firma/listado mediante otra policy. Probar que un cliente que invoque createSignedUrl directamente sea denegado; ocultar el botón no basta. Si los helpers por operación no están disponibles en el proyecto, retirar SELECT al móvil y mediar la lectura con Edge autenticada que devuelva bytes tras autorizar, sin generar enlaces reutilizables. [Helpers oficiales por operación](https://supabase.com/docs/guides/storage/schema/helper-functions).

Storage y DB requieren una saga de estados: carga, cuarentena, approved/rejected, retiro y limpieza pendiente. Si falla un paso, revocar primero lectura y reintentar limpieza. No editar storage.objects con SQL para simular borrado físico de bytes: usar Storage API desde proceso autorizado.

## Privacidad y ciclo de vida

CI, sangre, domicilio, nacimiento y salud no van en Auth metadata, JWT, logs ni capturas. El titular controla su perfil y el consentimiento de compartir datos/documentos por grupo. Admin de familia no es admin del sistema ni puede editar contraseñas/perfiles privados/presupuestos ajenos.

Las claves elevadas y accesos de CI tienen alcance mínimo y viven en secretos; ejemplos versionados solo contienen nombres/marcadores. No declarar cifrado de extremo a extremo: servicios confiables necesitan procesar los archivos. Retención, consentimiento de menores y obligaciones locales requieren revisión antes de datos reales; no se afirma cumplimiento legal por usar un proveedor.

## Pruebas negativas mínimas

Datos sintéticos: A/B grupos distintos, usuario multigrupo, admin, dos admins y último admin, miembro, ajeno, invitado pendiente, expulsado y sesión terminada. Ejecutar select/insert/update/delete y cada RPC con IDs ajenos mediante SDK/Data API real, intentando también saltarse las RPC con escritura directa. Verificar denegación o cero filas autorizadas, y ausencia de efectos secundarios; no exigir un código HTTP único para todos los casos de RLS.

Probar Storage con JWT, anon, sesión terminada y acceso revocado; controles de bytes y estado, no solo UI. Para JWT no expirado después de logout, comprobar el guard de sesión que se haya implementado, o registrar la vigencia residual como hallazgo. pgTAP/SQL debe cubrir policies, grants, FK y funciones; concurrencia necesita dos transacciones PostgreSQL reales. Los tests Flutter actuales solo verifican dominio y widgets.
