# Arquitectura y contrato de integración

## Decisión vigente ADR-001 / ADR-002

**Una aplicación móvil Flutter + Supabase directo.** El usuario aclaró que el stack de servidor de las diapositivas correspondía a otro proyecto; no es requisito de este producto. Supabase Auth gestiona las cuentas, PostgreSQL conserva los datos con RLS y Storage mantiene los archivos privados. No se construye un portal web ni una API propia intermedia.

Estado: arquitectura y contratos preparados para implementar. La app actual sigue siendo una demostración en memoria; no hay conexión, migraciones, RLS o funciones desplegadas que estos documentos certifiquen.

Flutter se organiza por funcionalidades: identity, family, documents y budget. Cada módulo tiene presentación, dominio y datos. La UI observa un ViewModel (ChangeNotifier inicialmente), los casos de uso operan sobre repositorios abstractos y el adaptador Supabase transforma DTOs en entidades. Inyección por constructor en el punto de composición; cliente Supabase compartido e inyectado, sin estado global mutable de usuario/grupo. La [guía oficial de Flutter](https://docs.flutter.dev/app-architecture/guide) fundamenta la separación de vistas, modelos de vista y repositorios.

~~~mermaid
flowchart LR
  V[Flutter / Material 3] --> VM[ViewModel por módulo]
  VM --> U[Casos de uso y dominio Dart]
  U --> R[Interfaz Repository]
  R --> D[Demo en memoria]
  R --> S[Adaptador supabase_flutter / DTO]
  S --> A[Supabase Auth]
  S --> DB[Data API + RLS + RPC PostgreSQL]
  S --> F[Storage privado + RLS]
  S --> E[Edge Functions para tareas privilegiadas]
  E --> DB
  E --> F
~~~

## Qué corresponde al cliente y qué a Supabase

| Capa | Responsabilidad |
|---|---|
| Flutter | Formularios, navegación, calendario mensual, feedback de validación, vista del árbol, cálculos de presentación y descarga CSV |
| Auth | Registro, verificación, acceso, recuperación, refresh y cierre de sesión |
| PostgreSQL | Integridad, FK, checks, RLS por usuario/grupo, idempotencia y transacciones |
| RPC SQL | Invariantes de varias filas: membresías/admins, invitaciones, ascendencia, categorías y movimientos |
| Storage | Objetos privados, rutas opacas y autorización con JWT + RLS en cada solicitud |
| Edge Functions | Búsqueda exacta con rate limit; verificación/escaneo de archivos y tareas administrativas que necesitan secretos |

La aplicación no guarda contraseñas ni credenciales PostgreSQL. Solo incorpora URL de proyecto y publishable key. La clave pública identifica el proyecto, **no autoriza acceso a filas**: los grants y RLS son obligatorios. Las secret/service_role keys quedan exclusivamente en funciones/servicios autorizados y nunca llegan al móvil.

## Contratos y propiedad de archivos

El contrato estable es [api/CONTRATO.md](api/CONTRATO.md), compuesto por llamadas SDK, tablas, RPC y funciones Edge; no por rutas de un servidor propio. Nombres PostgreSQL/JSON snake_case, Dart camelCase, UUID internos y public_id aleatorio separado. Dinero en amount_cents entero, fechas civiles YYYY-MM-DD e instantes UTC.

Gerardo custodia core, composición, pubspec/locks, cliente Supabase, contrato, config, esquema base y CI. Cada integrante agrega su módulo y migraciones SQL propias en supabase/migrations, con timestamp único y orden de dependencia acordado. Tests SQL/RLS en supabase/tests/database por módulo y funciones en supabase/functions. No reescribir migraciones ya aplicadas ni crear un único archivo compartido para todos.

Las operaciones simples pueden usar select/insert/update/delete del SDK **solo** cuando sus grants, políticas USING/WITH CHECK y restricciones impidan saltarse las reglas. Las escrituras críticas se revocan a anon/authenticated en las tablas y se exponen exclusivamente mediante RPC revisadas. Un botón oculto o una función que nadie está obligado a usar no es una barrera de seguridad.

## Modelo de datos y privacidad

~~~mermaid
erDiagram
  AUTH_USER ||--|| PROFILE : owns
  AUTH_USER ||--|| PRIVATE_PROFILE : owns
  AUTH_USER ||--o{ PROFILE_SHARE : consents
  AUTH_USER ||--o{ MEMBERSHIP : joins
  FAMILY ||--|{ MEMBERSHIP : contains
  FAMILY ||--o{ INVITATION : offers
  FAMILY ||--o{ RELATIONSHIP : links
  FAMILY ||--o{ PET : shelters
  FAMILY ||--o{ FOLDER : scopes
  FOLDER ||--o{ DOCUMENT : contains
  FAMILY ||--o{ BUDGET_SHEET : contextualizes
  AUTH_USER ||--o{ BUDGET_SHEET : owns
  BUDGET_SHEET ||--o{ CATEGORY : defines
  CATEGORY ||--o{ ENTRY : classifies
  BUDGET_SHEET ||--o{ ENTRY : records
~~~

Tablas de aplicación previstas en public, con grants mínimos y RLS desde su migración: profiles, private_profiles, profile_shares, families, memberships, invitations, relationships, pets, folders, documents, budget_sheets, categories y entries. Auditoría, claves de idempotencia y helpers internos se mantienen en esquema private no expuesto por Data API.

Profiles contiene solo nombre de presentación e ID público; su lectura se limita al titular y a miembros activos de un grupo común. Private_profiles contiene CI, sangre, nacimiento y domicilio y solo lo lee/escribe su titular. Profile_shares contiene únicamente los campos que el titular decidió compartir explícitamente con un grupo y conserva su consentimiento; no abre todo el perfil privado. RLS protege filas, por eso separar datos sensibles evita confiar en la lista de columnas que envía Flutter.

Claves: memberships (family_id,user_id) única; is_admin independiente de parentesco; invitación pendiente única familia/receptor; folders con titular humano o mascota (XOR); FK compuestas impiden relacionar carpeta/documento, categoría/movimiento o parentesco con otro grupo/hoja. Los paths Storage se generan a partir de IDs opacos y metadata persistida; no se autorizan por un prefijo enviado libremente desde el cliente.

## Invariantes transaccionales

- Crear grupo y primera membresía admin en una misma RPC.
- Al cambiar admin, expulsar o salir, bloquear primero la fila families con SELECT FOR UPDATE, volver a validar actor y contar admins; todas las rutas de cambio comparten ese orden. Revocar escrituras directas a memberships. Dos salidas simultáneas no dejan cero admins.
- Responder una invitación bloquea grupo e invitación; comprueba receptor, estado, vigencia e invitador todavía admin. La membresía se inserta bajo índice único y el reintento se deduplica.
- Mutar parentescos bloquea grupo y valida extremos y ausencia de ciclos con consulta recursiva. Parent es dirigido, partner/sibling se normalizan para evitar duplicados simétricos.
- Categoría y movimientos se validan dentro de RPC y con FK/checks. Bloquear categoría al comprobar su uso; misma hoja, tipo consistente, monto positivo y año/mes válidos. Revocar escritura directa que permita eludir la transacción.
- Archivo: reservar metadata -> cargar a cuarentena -> validar/escaneo en servicio confiable -> publicar objeto privado -> marcar approved. Storage y DB no son una transacción única: usar estados, idempotencia, compensación y limpieza reintentable.

## Seguridad y verificación

Preferir SECURITY INVOKER. Si una RPC necesita SECURITY DEFINER por grants revocados o helpers no recursivos, fijar search_path vacío, calificar esquemas, validar auth.uid() y autorización en el cuerpo, revocar EXECUTE a PUBLIC/anon y conceder solo las firmas necesarias. Una función definer puede sobrepasar RLS; concederla a authenticated no significa que ya esté autorizada por usuario. [Funciones de base de datos Supabase](https://supabase.com/docs/guides/database/functions).

Para datos familiares, RLS consulta membresía vigente en DB en lugar de guardar el rol de familia únicamente en el JWT. El logout limpia sesión y cachés del cliente, pero un JWT previamente emitido puede seguir válido hasta expirar; para acciones sensibles se requiere diseñar/probar además un helper restringido que compruebe session_id contra auth.sessions. Los bytes ya descargados no se revocan retroactivamente. [Sesiones Supabase](https://supabase.com/docs/guides/auth/sessions).

El CI actual prueba Flutter y el generador de reportes. Tests SQL/pgTAP y de integración Auth/RLS/Storage sobre un entorno Supabase de pruebas se agregan en las historias correspondientes; no están implementados por este cambio documental.
