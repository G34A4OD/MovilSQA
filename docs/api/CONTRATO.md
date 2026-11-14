# Contrato HTTP v1 · Nido

Estado: **diseño para implementación**, no endpoints ya desplegados. Gerardo custodia este archivo. Cambios incompatibles requieren PR de contrato antes de UI/API. Prefijo `/api/v1`; JSON UTF-8 y `Authorization: Bearer <token>` salvo autenticación. No introducir tokens reales en ejemplos.

## Convenciones

IDs internos UUID; `public_id` de usuario aleatorio, único, distinto del UUID. Campos JSON snake_case. Paginación `?page=1&per_page=20`, máximo 100. Respuesta de lista `{ "data": [], "meta": {"current_page":1,"last_page":1} }`; individual `{ "data": {} }`. Errores `{ "error": { "code":"last_admin", "message":"Designa otro administrador.", "fields":{}, "request_id":"uuid" } }`. 201 creado, 200 leído/editado, 204 borrado, 401 sin sesión, 403 sin facultades, 404 objeto fuera de alcance, 409 conflicto, 422 validación, 429 límite. No filtrar existencia de recursos de otros grupos en errores.

Fechas civiles `YYYY-MM-DD`, instante UTC ISO-8601; cantidades enteras `amount_cents` entre 1 y 99999999999, moneda inicial BOB. Año 1-9999, mes 1-12. No generar fechas UTC a partir de cumpleaños. `Idempotency-Key` UUID en creación de movimiento y aceptación de invitación, deduplicación por usuario/ruta/cuerpo 24 h; reutilizar con otro cuerpo devuelve 409. Conflictos de edición con `version` entero y comparación optimista.

## Endpoints y autoridad

| Método / ruta | Entrada principal | Autorización y salida |
|---|---|---|
| POST `/auth/register` | email, password, password_confirmation, full_name, birth_date, blood_type, identity_card, address | Visitante con límite; 201 perfil mínimo, verificación pendiente |
| POST `/auth/login` | email, password, device_name | Límite por IP/cuenta, verificación según política; token con expiración |
| POST `/auth/forgot-password` | email | Respuesta genérica aunque no exista |
| POST `/auth/reset-password` | email, token, password, password_confirmation | Token de un uso |
| POST `/auth/logout` | — | Revoca token actual; 204 |
| GET/PATCH `/me` | Campos editables de perfil en PATCH | Titular; nunca aceptar is_admin o public_id del cliente |
| GET `/users/lookup?public_id=...&family_id=...` | ID exacto | Solo admin de esa familia; solo nombre e ID, no listado global |
| GET/POST `/families` | POST `{name}` | Lista solo mis grupos; creador admin |
| GET/PATCH/DELETE `/families/{family}` | PATCH `{name,version}` | GET miembro activo; cambios admin; borrar requiere confirmación/reautenticación |
| GET `/invitations` | — | Solo invitaciones dirigidas al usuario actual |
| POST `/families/{family}/invitations` | `{target_public_id}` | Solo admin; expiración 7 días, sin duplicado pendiente |
| POST `/invitations/{invitation}/respond` | `{decision:"accept"|"reject"}` | Solo receptor; verificar estado/vigencia/invitador |
| DELETE `/families/{family}/invitations/{invitation}` | — | Admin de mismo grupo; revoca pendiente |
| GET `/families/{family}/members` | — | Miembro activo; perfil mínimo más datos con consentimiento |
| PATCH `/families/{family}/members/{user}/admin` | `{is_admin:true|false}` | Admin; último admin protegido, permite renuncia propia |
| DELETE `/families/{family}/members/{user}` | — | Admin o usuario saliendo de sí mismo; último admin protegido |
| GET/POST `/families/{family}/relationships` | `{source_id,target_id,kind}` | GET miembro; POST admin. kind: parent, partner, sibling; parent dirigido progenitor -> descendiente |
| PATCH/DELETE `/families/{family}/relationships/{relation}` | Relación validada en PATCH | Admin, dos extremos del mismo grupo, sin ciclos |
| GET/POST `/families/{family}/pets` | `{name,species,birth_date?}` | GET miembro; POST admin |
| PATCH/DELETE `/families/{family}/pets/{pet}` | Campos mascota | Admin; no borrar archivos sin confirmación |
| GET/POST `/families/{family}/folders` | `{name,owner_user_id?,pet_id?}` | Miembro crea para sí; admin para mascota. XOR de titulares |
| PATCH/DELETE `/families/{family}/folders/{folder}` | `{name,version}` | Titular o moderación admin auditada; comprobar grupo de carpeta |
| GET `/families/{family}/folders/{folder}/documents` | — | Miembro activo con carpeta compartida |
| POST `/families/{family}/folders/{folder}/documents` | multipart: title, description, expires_on?, file, consent=true | Titular humano o admin de mascota; 202 si escaneo pendiente, estado quarantined |
| PATCH `/families/{family}/documents/{document}` | title, description, expires_on?, version | Titular/admin moderador; reemplazo archivo por endpoint multipart `/replacement` |
| DELETE `/families/{family}/documents/{document}` | — | Titular/admin moderador; revocar primero, limpiar archivo por tarea |
| GET `/families/{family}/documents/{document}/content` | — | Miembro activo y archivo approved; stream privado con no-store |
| GET/POST `/budget-sheets` | POST `{family_id,name}` | Propietario actual y membresía activa; nombre de hoja obligatorio |
| GET/PATCH/DELETE `/budget-sheets/{sheet}` | PATCH `{name,version}` | Titular + miembro activo. No cambiar family_id silenciosamente |
| GET/POST `/budget-sheets/{sheet}/categories` | `{name,description,kind}` | Titular; kind income/expense |
| PATCH/DELETE `/budget-sheets/{sheet}/categories/{category}` | Campos y version | Titular; usada no se elimina ni cambia tipo |
| GET/POST `/budget-sheets/{sheet}/entries` | GET year; POST `{category_id,year,month,amount_cents,description}` | Titular; categoría de misma hoja, monto positivo |
| PATCH/DELETE `/budget-sheets/{sheet}/entries/{entry}` | Mismos campos y version | Titular; revalidar todos los alcances |
| GET `/budget-sheets/{sheet}/summary?year=2026` | year | `{months:[{month,income_cents,expense_cents,balance_cents}],total:{...}}`, siempre 12 meses |
| GET `/budget-sheets/{sheet}/export.csv?year=2026` | year | Titular; Content-Type text/csv; charset=utf-8, Content-Disposition attachment |

## Recursos mínimos

```json
{
  "family": {"id":"uuid", "name":"Casa Rivera", "my_is_admin":true, "version":1},
  "member": {"user_id":"uuid", "public_id":"NIDO-7DXQ4MH9K2", "full_name":"Persona de prueba", "is_admin":false},
  "document": {"id":"uuid", "folder_id":"uuid", "title":"Vacunas", "description":"Ejemplo ficticio", "expires_on":null, "mime_type":"application/pdf", "size_bytes":1200, "status":"approved"},
  "category": {"id":"uuid", "sheet_id":"uuid", "name":"Alimentación", "description":"", "kind":"expense"},
  "entry": {"id":"uuid", "sheet_id":"uuid", "category_id":"uuid", "year":2026, "month":1, "amount_cents":12550, "description":"Compra de prueba", "version":1}
}
```

Los ejemplos usan `uuid` como marcador, nunca enviar esa cadena a un endpoint real. No devolver rutas físicas, claves de bucket ni token de otro usuario. Los adaptadores Dart convierten DTOs a modelos de dominio; no pasar `Map<String,dynamic>` directamente a widgets. Persistencia de sesión segura, reintentos con idempotencia y manejo uniforme de error pertenecen al adaptador compartido, no a cada pantalla.
