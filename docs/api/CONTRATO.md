# Contrato Supabase v2 · Nido móvil

**Contrato de integración; estado por módulo.** Sustituye el contrato de rutas de servidor propio. Flutter consume Supabase con supabase_flutter: Auth, Data API protegida por RLS, RPC PostgreSQL y Storage privado; Edge Functions solo para tareas que lo necesitan. Identidad/familia y lookup-user están desplegados; documentos/Storage, presupuesto, delete-account y worker de purga siguen previstos. No hay endpoints propios bajo /api/v1. Gerardo custodia cambios de contrato antes de consumidores.

## Convenciones

UUID interno; auth.users.id es el user_id de la aplicación. Public_id aleatorio único generado en DB, nunca CI o ID secuencial. JSON/columnas snake_case, Dart camelCase. Fechas civiles YYYY-MM-DD, instantes UTC ISO-8601, amount_cents entero entre 1 y 99999999999, BOB, año 1-9999 y mes 1-12. Descripción/categoría no interpretan fórmulas al exportar.

Filas tienen version entero cuando admiten edición concurrente; mutaciones reciben p_expected_version y fallan sin cambios parciales si no coincide. Creaciones/reintentos delicados reciben p_request_id UUID: deduplicación por actor+operación+cuerpo durante 24 h en tabla privada; mismo ID con cuerpo distinto se rechaza. El cliente no fabrica fechas de expiración, actor, escaneo aprobado ni privilegios.

Select devuelve las filas autorizadas por RLS, no un envelope propio de paginación. Repositorios piden columnas explícitas, order estable y range con tamaño máximo 100; normalizan lista/vacío/no encontrado. PostgrestException/AuthException/StorageException y respuestas Edge se traducen a errores de dominio. No suponer que RLS siempre devuelve 403: un SELECT ajeno puede devolver cero filas. RPC de negocio emite códigos estables last_admin, invitation_unavailable, category_in_use, invalid_relationship, version_conflict, validation_error y forbidden sin datos de otro grupo.

## Tablas y acceso directo previsto

La matriz se implementa mediante **grants, policies, FK, checks y funciones**. Identidad/familia están implementadas; folders/documents/budget_sheets/categories/entries son contrato para los siguientes módulos. Permisos no mencionados están denegados; anon no lee datos familiares.

| Tabla | SELECT authenticated | Escritura desde cliente |
|---|---|---|
| profiles | Titular o miembro activo de grupo común; solo nombre/public_id | Completar/editar perfil propio por complete_profile; public_id inmutable |
| private_profiles | Solo titular; CI, sangre, nacimiento, domicilio | complete_profile/update_profile, actor derivado de auth.uid |
| profile_shares | Titular o miembro activo del grupo autorizado; solo datos consentidos | RPC set_profile_share por titular, no copia automática de campos privados |
| families | Mis grupos activos | RPC create_family/update_family/delete_family |
| memberships | Miembros activos del mismo grupo | DML directo revocado; solo RPC de membresía |
| invitations | Receptor o admin del grupo | Solo RPC; receptor no modifica destinatario ni is_admin |
| relationships | Miembro activo del grupo | RPC de grafo; sin DML que eluda ciclos |
| pets | Miembro activo | CRUD con RLS admin y checks; borrar mediante RPC delete_pet si tiene archivos asociados |
| folders | Miembro activo con carpeta compartida; titular propio | CRUD con RLS y FK/XOR; borrado no vacío mediante delete_folder |
| documents | Approved compartido para miembros; estados propios para titular | RPC de metadata; cliente nunca marca approved ni cambia path/grupo |
| budget_sheets | Titular + miembro activo del grupo | create_budget_sheet y cambios propios protegidos; family_id inmutable |
| categories | Titular de hoja + miembro activo | RPC de categoría, sin DML alternativo |
| entries | Titular de hoja + miembro activo | RPC de movimiento, sin DML alternativo |

Profiles no es un directorio abierto para todos los usuarios autenticados. Si se necesita buscar alguien fuera del grupo, lookup-user es la única salida mínima y limitada. Las tablas audit_events, request_dedup y helpers de autorización se mantienen en esquema private no expuesto por Data API.

## Auth y perfil · Gerardo

| Operación | SDK / contrato | Resultado y autorización |
|---|---|---|
| Cuenta | auth.signUp(email,password) | Confirmación de correo; no inferir sesión si el proyecto requiere verificar |
| Acceso | auth.signInWithPassword | AuthResponse o AuthException; no enumerar cuentas en UI |
| Recuperación | auth.resetPasswordForEmail + deep link y auth.updateUser | Flujo propio de Auth; no endpoint de contraseña casero |
| Salida | auth.signOut, scope explícito | Limpiar sesión/cachés; JWT previo puede vivir hasta expirar |
| Completar perfil | rpc complete_profile(p_full_name,p_blood_type,p_identity_card,p_birth_date,p_address) | Actor actual; creación atómica inicial; public_id generado en DB. Perfil existente exige update_profile para no eludir versión |
| Editar perfil | rpc update_profile(p_full_name,p_blood_type,p_identity_card,p_birth_date,p_address,p_expected_version) | Campos propios; no is_admin/public_id/user_id arbitrarios |
| Compartir datos | rpc set_profile_share(p_family_id,p_selected_fields,p_request_id) | Solo titular y miembro activo; guardar consentimiento y únicamente campos seleccionados |
| Borrar cuenta (pendiente, no desplegado) | Edge delete-account | JWT verificado, reautenticación reciente, resolver último admin y limpieza; Auth Admin solo en función confiable |

Las contraseñas solo llegan a Supabase Auth. No guardar datos sensibles en user_metadata/app_metadata o claims. Tokens persistidos con almacenamiento seguro; para datos sensibles implementar/probar guard de sesión vigente como en SEGURIDAD.md.

La opción de tipo de sangre «No sé» se persiste como null. Solo se aceptan los ocho grupos sanguíneos del check; no se amplía a texto libre. Ajuste solicitado por Waldir en la revisión del PR #25, entregado en OPS-01 #20.

HU-02 implementa p_selected_fields como text[] con nombres de campos permitidos (blood_type, identity_card, birth_date, address). El servidor copia solo esos valores del perfil propio al snapshot consentido; [] retira los datos compartidos. Actualizar el perfil privado no cambia silenciosamente un consentimiento previo: volver a compartir para publicar un nuevo snapshot. Reintentos con mismo request/cuerpo son idempotentes; otro cuerpo da request_conflict. complete_profile repetido da profile_exists; update_profile sin versión vigente da version_conflict.

## Familia · Gerardo

Todas las RPC extraen auth.uid(), comprueban sesión/permisos y trabajan sobre recursos del grupo indicado, sin confiar en actor_id enviado. Las funciones con lock bloquean primero families para evitar carreras.

| RPC / función | Parámetros principales | Regla / salida |
|---|---|---|
| create_family | p_name,p_request_id | Grupo + creador admin en una transacción; devuelve family |
| update_family / delete_family | p_family_id, campos permitidos/version o confirmación | Admin; borrado con reautenticación y limpieza de archivos programada |
| Edge lookup-user | family_id,public_id exacto | JWT+admin+rate limit; devuelve solo public_id/full_name o coincidencia no disponible |
| invite_member | p_family_id,p_target_public_id,p_request_id | Solo admin; no auto invitación/duplicado pendiente; caduca en 7 días |
| respond_invitation | p_invitation_id,p_decision,p_request_id | Solo receptor; accept/reject, vigencia/invitador válidos; lock y estado final |
| revoke_invitation | p_invitation_id | Solo admin del grupo; revoca pendiente |
| set_member_admin | p_family_id,p_target_user_id,p_is_admin | Admin; renuncia propia permitida; nunca cero admins |
| leave_family / remove_member | p_family_id[,p_target_user_id] | Salida propia o expulsión por admin; mismo lock y protección de último admin; retirar documentos/acceso del saliente |
| save_relationship / delete_relationship | p_family_id, IDs de relación, kind/version | Admin; ascendencia dirigida, vínculos laterales; extremos del mismo grupo, sin auto relación ni ciclo |
| delete_pet | p_pet_id,p_expected_version | Admin, mismo grupo; revocar referencias documentales y programar limpieza |

Las lecturas de grupos/membresías/invitaciones/parentescos/mascotas son select filtrados y paginados, siempre sujetos a RLS. El ID público por sí solo nunca otorga acceso.

HU-03 implementa update_family(p_family_id,p_name,p_expected_version) y delete_family(p_family_id,p_expected_version,p_confirmation), donde p_confirmation es el nombre exacto. El borrado marca families.deleted_at y encola private.cleanup_jobs sin retirar metadata antes de limpiar archivos. Los helpers de pertenencia/admin/grupo común excluyen familias borradas. La reautenticación se comprueba por método password reciente en amr (10 minutos), no por iat de un JWT renovado. El móvil confirma con Auth antes de llamar a delete_family. La purga física corresponde a la integración OPS/documentos y se demuestra aparte.

HU-04: Edge lookup-user verifica el JWT mediante Auth y llama lookup_family_user(p_family_id,p_public_id) con el JWT del usuario, sin secret/service_role. El RPC también es alcanzable directamente por authenticated: aplica los mismos controles de admin, sesión vigente, ID exacto y límite de 10 consultas/minuto por actor, incluso para búsquedas sin coincidencia. No existe un directorio abierto ni búsqueda por nombre/correo/CI. La función Edge valida Auth en su cuerpo (verify_jwt=false para compatibilidad con claves de firma actuales); esto no permite uso anónimo.

invite_member devuelve {error: invitation_unavailable} para destinos no disponibles/repetidos; el adaptador lo transforma en fallo de dominio. No se lanza excepción en ese resultado, para que el contador de intentos se confirme en la transacción. Los permisos/sesión y demás RPC siguen devolviendo errores SQL estables. accepted/rejected/revoked/expired son estados finales; caducidad y permisos del invitador se revalidan al aceptar. Familias borradas no muestran invitaciones.

HU-05: set_member_admin/leave_family/remove_member bloquean primero families y vuelven a validar sesión/membresía/admin. membership_revision cambia bajo ese lock para impedir snapshots obsoletos también en REPEATABLE READ. La salida/expulsión inactiva membresía, quita admin, retira profile_shares y revoca invitaciones pendientes del saliente; cambiar parentesco nunca cambia administración. El último admin recibe last_admin. Un reingreso explícito entra sin restaurar privilegios previos.

La salida rota memberships.access_epoch. **Integración obligatoria de Eva:** folders/documents de titular humano guardan owner_access_epoch obtenido del servidor y sus policies/RPC exigen dueño activo y coincidencia con memberships.access_epoch además del lector activo. Así un reingreso no vuelve a compartir archivos antiguos sin nuevo consentimiento. Para mascotas se aplica pertenencia/admin y estado de mascota; no hay usuario Auth de mascota. Un cliente no elige el epoch ni el dueño. private.cleanup_jobs guarda la generación retirada en metadata; el worker limpia solo generaciones retiradas y usa corte temporal/lease para no borrar archivos de un reingreso. Hasta demostrar RLS/Storage del módulo de archivos, las pruebas de membresía no acreditan revocación de bytes.

HU-06 amplía kinds a parent/grandparent/uncle (dirigidos) y sibling/cousin/partner (simétricos normalizados). Las etiquetas hijo/nieto/sobrino invierten origen/destino al guardar. Esto permite declarar abuelos/tíos aunque el familiar intermedio todavía no tenga cuenta; no infiere permisos ni certifica datos biológicos. Los ciclos se prohíben en ascendencia parent/grandparent, bajo lock de familia y relationship_revision para concurrencia/isolation. Cada vínculo conserva los access_epoch de ambos extremos y no reaparece automáticamente tras una salida/reingreso.

Firmas HU-06: save_relationship(p_family_id,p_relationship_id,p_from_user_id,p_to_user_id,p_kind,p_expected_version,p_request_id) devuelve relación; id/version null para creación. delete_relationship(p_family_id,p_relationship_id,p_expected_version). Toda creación/edición se deduplica por actor/request/cuerpo. El árbol móvil dibuja ascendencia y lista también los vínculos laterales con texto accesible.

HU-07: pets tiene unique(family_id,id) para FK compuestas de Eva, sin cuenta Auth. save_pet(p_family_id,p_pet_id,p_name,p_species,p_birth_date,p_notes,p_expected_version,p_request_id), id/version null al crear; nombre/especie obligatorios, nacimiento opcional y notas limitadas. Todas las escrituras pasan por RPC admin. delete_pet(p_pet_id,p_expected_version) marca deleted_at y encola limpieza, sin borrar metadata antes de los archivos. Los permisos de carpetas/documentos de mascota deben exigir mascota vigente del mismo grupo además de lector/actor autorizado; una FK sola no comprueba deleted_at.

## Documentos y archivos · Eva

Carpeta: name no vacío de hasta 100 caracteres, family_id y exactamente uno de owner_user_id o pet_id. Miembro crea para sí; admin puede crear para mascota. Todos los IDs asociados deben pertenecer al mismo grupo mediante FK/checks y autorización.

| Operación | Contrato | Regla |
|---|---|---|
| Carpetas | CRUD folders bajo RLS; lectura/alta/renombre con policies; titular humano o mascota (XOR) | Miembro crea para sí; admin crea para mascota vigente; `owner_access_epoch` lo sella el servidor |
| Borrar carpeta | rpc `delete_folder(p_folder_id uuid, p_expected_version integer)` → `void` | Titular o admin moderador con sesión vigente; en la misma transacción marca `folders.deleted_at` (tombstone que conserva identidad y datos de titular), escribe `private.audit_events` y encola `private.cleanup_jobs` con `operation='delete_folder'`. El tombstone impide reutilizar el mismo `id` mientras la limpieza siga pendiente. Errores estables: `forbidden` (sin permiso, carpeta ausente o sesión/membresía inválida), `version_conflict` (versión distinta). Si falla el encolado, no se retira la carpeta. El worker de purga física sigue pendiente |
| Reservar carga | rpc begin_document_upload(p_folder_id,p_title,p_description,p_expires_on,p_filename,p_size_bytes,p_request_id) | Titular/admin mascota, consentimiento; devuelve document_id y path opaco en cuarentena |
| Cargar | storage.from('nido-quarantine').upload(path,file,upsert:false) | Solo ruta reservada propia, tamaño/tipo limitados; sin lectura familiar |
| Procesar | Edge process-document(document_id) | Autorización, verificar bytes reales y escaneo confiable; mover/publicar privado, marcar approved; reintento idempotente |
| Editar metadata | rpc update_document(p_document_id,campos,p_expected_version) | Titular/admin moderador, alcance validado; no status/path/owner arbitrarios |
| Reemplazar archivo | Nueva reserva/versionado de cuarentena | No sobrescribir objeto aprobado; reemplazo solo tras validación, limpiar versión anterior |
| Eliminar | rpc delete_document(p_document_id,p_expected_version) | Retirar acceso primero y encolar borrado Storage reintentable |
| Leer bytes | storage.from('nido-documents').download(path) | Bucket privado, JWT y SELECT RLS contra documento approved y miembro activo; no getPublicUrl/createSignedUrl |

PDF/JPG/PNG y máximo 10 MiB. Nombre UUID, contenido/MIME/firma/escáner validados fuera del cliente. Si el escáner no está disponible, mantener cuarentena. Metadata y Storage tienen compensación, no una transacción SQL única. Policies de storage.objects comprueban metadata y grupo; no autorizan por prefijo de path solamente.

La policy SELECT debe limitarse a object.get_authenticated y object.get_authenticated_info mediante storage.allow_any_operation, evitando que ese mismo permiso permita emitir URLs firmadas. Validar helper/operaciones de la versión desplegada y probar denegación de createSignedUrl con cliente adverso. Si no hay separación de operaciones disponible, usar Edge de lectura con JWT + autorización de metadata y retorno de bytes; en ese caso no conceder SELECT Storage directo al móvil. La ausencia de URLs firmadas es un control verificable, no una convención de UI.

Documentos llevan categoría orientativa (`identity_civic`, `civil_life`, `social_labor_tax`, `health`) en metadata vía `begin_document_upload` / `update_document`. En `health`, `health_note_kind` es opcional: `null` = documento médico general; notas específicas usan `allergy`/`consultation`/`prescription`/`vaccine`. Fuera de `health`, `health_note_kind` debe ser null. Autor = `uploaded_by` y fechas = `created_at`/`updated_at`/`expires_on`. El contenido no se copia a logs. Una copia descargada al teléfono no se revoca después; limpiar cachés y avisar antes de exportar.

## Presupuesto · Waldir

Solo dueño de hoja y miembro activo accede; ser admin del grupo no concede acceso a hojas ajenas. Categorías/entries comparten sheet_id por FK y tipo consistente. RLS protege lecturas; revocar escrituras directas de categorías/movimientos que evadan las RPC.

| RPC / operación | Parámetros | Regla / salida |
|---|---|---|
| create_budget_sheet | p_family_id,p_name,p_request_id | Cualquier miembro; owner_id=auth.uid; nombre obligatorio |
| Actualizar/eliminar hoja | Escritura RLS propia con version o RPC si hay cascada | Grupo inmutable; confirmar cascada; no reasignar propietario |
| save_budget_category | p_sheet_id,p_category_id?,p_name,p_description,p_kind,p_expected_version? | income/expense; bloquear categoría, impedir cambio de tipo si usada |
| delete_budget_category | p_category_id,p_expected_version | Bloquear y rechazar si tiene movimientos |
| save_budget_entry | p_sheet_id,p_entry_id?,p_category_id,p_year,p_month,p_amount_cents,p_description,p_request_id,p_expected_version? | Monto/límites/hoja/tipo válidos en transacción; deduplicar creación |
| delete_budget_entry | p_entry_id,p_expected_version | Solo dueño; eliminación y recálculo lógico sin duplicados |
| budget_year_summary | p_sheet_id,p_year | Doce months con income_cents/expense_cents/balance_cents y total; año vacío en cero |
| Descargar CSV | Repositorio Flutter lee todas las páginas autorizadas del año y exporta localmente | RFC4180/UTF-8, fórmulas de texto neutralizadas, doce resúmenes y total; no URL pública |

Si durante una exportación concurrente se necesita snapshot consistente de filas+totales, usar una RPC de exportación con el mismo alcance y paginación/snapshot acordados antes de integrar; no combinar silenciosamente datos y totales de instantes distintos. Especificar ese caso en la HU-15 al implementarla.

## Recursos de ejemplo y pruebas

~~~json
{
  "family": {"id":"uuid","name":"Casa Rivera","version":1},
  "membership": {"family_id":"uuid","user_id":"uuid","is_admin":false},
  "document": {"id":"uuid","folder_id":"uuid","title":"Vacunas","description":"Ejemplo ficticio","expires_on":null,"mime_type":"application/pdf","size_bytes":1200,"status":"approved"},
  "category": {"id":"uuid","sheet_id":"uuid","name":"Alimentación","description":"","kind":"expense"},
  "entry": {"id":"uuid","sheet_id":"uuid","category_id":"uuid","year":2026,"month":1,"amount_cents":12550,"description":"Compra ficticia","version":1}
}
~~~

uuid es un marcador, no un ID para enviar. Repositorios transforman DTOs; no pasar mapas crudos a widgets. Grants y RLS se comprueban también intentando escrituras directas y RPC con IDs ajenos; una llamada mediante service_role no prueba permisos del móvil.

Antes de Done: tests SQL/pgTAP de policies/grants/FK/RPC, dos transacciones reales para último admin, integración Auth/Storage con cuentas A/B y pruebas Android/iOS. CI ejecuta Flutter/reportes y SQL/Auth/Edge/concurrencia de identidad/familia; OPS agrega compilación Android. Storage y presupuesto no se dan por probados por esos resultados.

Fuentes primarias: [SDK Flutter](https://supabase.com/docs/reference/dart/initializing), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [funciones](https://supabase.com/docs/guides/database/functions), [Storage privado](https://supabase.com/docs/guides/storage/buckets/fundamentals), [sesiones](https://supabase.com/docs/guides/auth/sessions).
