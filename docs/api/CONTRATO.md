# Contrato Supabase v2 · Nido móvil

**Diseño para implementación.** Sustituye el contrato de rutas de servidor propio. Flutter consume Supabase con supabase_flutter: Auth, Data API protegida por RLS, RPC PostgreSQL y Storage privado; Edge Functions solo para tareas que lo necesitan. No hay endpoints propios bajo /api/v1 ni controles ya desplegados. Gerardo custodia cambios de contrato antes de consumidores.

## Convenciones

UUID interno; auth.users.id es el user_id de la aplicación. Public_id aleatorio único generado en DB, nunca CI o ID secuencial. JSON/columnas snake_case, Dart camelCase. Fechas civiles YYYY-MM-DD, instantes UTC ISO-8601, amount_cents entero entre 1 y 99999999999, BOB, año 1-9999 y mes 1-12. Descripción/categoría no interpretan fórmulas al exportar.

Filas tienen version entero cuando admiten edición concurrente; mutaciones reciben p_expected_version y fallan sin cambios parciales si no coincide. Creaciones/reintentos delicados reciben p_request_id UUID: deduplicación por actor+operación+cuerpo durante 24 h en tabla privada; mismo ID con cuerpo distinto se rechaza. El cliente no fabrica fechas de expiración, actor, escaneo aprobado ni privilegios.

Select devuelve las filas autorizadas por RLS, no un envelope propio de paginación. Repositorios piden columnas explícitas, order estable y range con tamaño máximo 100; normalizan lista/vacío/no encontrado. PostgrestException/AuthException/StorageException y respuestas Edge se traducen a errores de dominio. No suponer que RLS siempre devuelve 403: un SELECT ajeno puede devolver cero filas. RPC de negocio emite códigos estables last_admin, invitation_unavailable, category_in_use, invalid_relationship, version_conflict, validation_error y forbidden sin datos de otro grupo.

## Tablas y acceso directo previsto

La siguiente es una matriz a implementar mediante **grants, policies, FK, checks y funciones**. Permisos no mencionados están denegados; anon no lee datos familiares.

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
| Borrar cuenta | Edge delete-account | JWT verificado, reautenticación reciente, resolver último admin y limpieza; Auth Admin solo en función confiable |

Las contraseñas solo llegan a Supabase Auth. No guardar datos sensibles en user_metadata/app_metadata o claims. Tokens persistidos con almacenamiento seguro; para datos sensibles implementar/probar guard de sesión vigente como en SEGURIDAD.md.

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
| save_relationship / delete_relationship | p_family_id, IDs de relación, kind/version | Admin; parent dirigido, partner/sibling simétricos; extremos del mismo grupo, sin auto relación ni ciclo |
| delete_pet | p_pet_id,p_expected_version | Admin, mismo grupo; revocar referencias documentales y programar limpieza |

Las lecturas de grupos/membresías/invitaciones/parentescos/mascotas son select filtrados y paginados, siempre sujetos a RLS. El ID público por sí solo nunca otorga acceso.

HU-03 implementa update_family(p_family_id,p_name,p_expected_version) y delete_family(p_family_id,p_expected_version,p_confirmation), donde p_confirmation es el nombre exacto. El borrado marca families.deleted_at y encola private.cleanup_jobs sin retirar metadata antes de limpiar archivos. Los helpers de pertenencia/admin/grupo común excluyen familias borradas. La reautenticación se comprueba por método password reciente en amr (10 minutos), no por iat de un JWT renovado. El móvil confirma con Auth antes de llamar a delete_family. La purga física corresponde a la integración OPS/documentos y se demuestra aparte.

## Documentos y archivos · Eva

Carpeta: name no vacío de hasta 100 caracteres, family_id y exactamente uno de owner_user_id o pet_id. Miembro crea para sí; admin puede crear para mascota. Todos los IDs asociados deben pertenecer al mismo grupo mediante FK/checks y autorización.

| Operación | Contrato | Regla |
|---|---|---|
| Carpetas | CRUD folders bajo RLS; rpc delete_folder para cascada | Titular o admin moderador auditado; confirmar borrado y limpieza |
| Reservar carga | rpc begin_document_upload(p_folder_id,p_title,p_description,p_expires_on,p_filename,p_size_bytes,p_request_id) | Titular/admin mascota, consentimiento; devuelve document_id y path opaco en cuarentena |
| Cargar | storage.from('nido-quarantine').upload(path,file,upsert:false) | Solo ruta reservada propia, tamaño/tipo limitados; sin lectura familiar |
| Procesar | Edge process-document(document_id) | Autorización, verificar bytes reales y escaneo confiable; mover/publicar privado, marcar approved; reintento idempotente |
| Editar metadata | rpc update_document(p_document_id,campos,p_expected_version) | Titular/admin moderador, alcance validado; no status/path/owner arbitrarios |
| Reemplazar archivo | Nueva reserva/versionado de cuarentena | No sobrescribir objeto aprobado; reemplazo solo tras validación, limpiar versión anterior |
| Eliminar | rpc delete_document(p_document_id,p_expected_version) | Retirar acceso primero y encolar borrado Storage reintentable |
| Leer bytes | storage.from('nido-documents').download(path) | Bucket privado, JWT y SELECT RLS contra documento approved y miembro activo; no getPublicUrl/createSignedUrl |

PDF/JPG/PNG y máximo 10 MiB. Nombre UUID, contenido/MIME/firma/escáner validados fuera del cliente. Si el escáner no está disponible, mantener cuarentena. Metadata y Storage tienen compensación, no una transacción SQL única. Policies de storage.objects comprueban metadata y grupo; no autorizan por prefijo de path solamente.

La policy SELECT debe limitarse a object.get_authenticated y object.get_authenticated_info mediante storage.allow_any_operation, evitando que ese mismo permiso permita emitir URLs firmadas. Validar helper/operaciones de la versión desplegada y probar denegación de createSignedUrl con cliente adverso. Si no hay separación de operaciones disponible, usar Edge de lectura con JWT + autorización de metadata y retorno de bytes; en ese caso no conceder SELECT Storage directo al móvil. La ausencia de URLs firmadas es un control verificable, no una convención de UI.

Documentos de salud/notas de alergias/recetas/vacunas llevan título, descripción, autor y fechas como el resto. El contenido no se copia a logs. Una copia descargada al teléfono no se revoca después; limpiar cachés y avisar antes de exportar.

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

Antes de Done: tests SQL/pgTAP de policies/grants/FK/RPC, dos transacciones reales para último admin, integración Auth/Storage con cuentas A/B y pruebas Android/iOS. El CI actual solo ejecuta la base Flutter/reportes; estos contratos no certifican seguridad ya aplicada.

Fuentes primarias: [SDK Flutter](https://supabase.com/docs/reference/dart/initializing), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [funciones](https://supabase.com/docs/guides/database/functions), [Storage privado](https://supabase.com/docs/guides/storage/buckets/fundamentals), [sesiones](https://supabase.com/docs/guides/auth/sessions).
