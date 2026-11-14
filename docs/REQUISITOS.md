# Alcance y reglas de Nido

## Actores y separación de roles

Usuario registrado, miembro de uno o varios grupos, administrador **de un grupo**, propietario de una hoja financiera. El parentesco (padre, hija, abuela, tío, hermano, sobrino, primo, etc.) no concede permisos administrativos. Una mascota es una entidad del grupo sin cuenta ni facultades administrativas.

## Catálogo funcional

| ID / HU | EDT | Funcionalidad y aceptación verificable | Responsable |
|---|---|---|---|
| RF-01 / HU-01 | 3.1 | Crear cuenta, verificar correo, iniciar/cerrar sesión y recuperar contraseña. Contraseña nunca recuperable en texto. | Gerardo |
| RF-02 / HU-02 | 3.1 | Perfil: nombre completo, sangre con «No sé», CI, nacimiento completo válido, domicilio y ID público aleatorio único. Edición por titular. | Gerardo |
| RF-03 / HU-03 | 3.2 | Crear, ver, renombrar y eliminar grupo; creador es admin. Listar todos mis grupos y cambiar grupo activo sin mezclar datos. Borrado confirmado y auditado. | Gerardo |
| RF-04 / HU-04 | 3.2 | Solo admin busca ID público exacto e invita; receptor acepta/rechaza, solo una vez. Invitación pendiente no da acceso. No duplicados ni auto invitación. | Gerardo |
| RF-05 / HU-05 | 3.2 | Admin promueve/degrada/elimina miembros. Cada miembro puede salir o renunciar a admin; último admin debe transferir antes. Operación atómica incluso con concurrencia. | Gerardo |
| RF-06 / HU-06 | 3.3 | Admin asigna parentescos con otro miembro del mismo grupo. Guardar padre/madre-progenitor, pareja y hermanos sin auto relaciones ni ciclos de ascendencia; mostrar árbol/red. | Gerardo |
| RF-07 / HU-07 | 3.3 | Admin crea/edita/elimina mascota; tarjeta separada, especie/nombre/fecha opcional y carpetas documentales. | Gerardo |
| RF-08 / HU-08 | 3.4 | Cada miembro crea/edita/elimina carpetas propias **dentro de un grupo** con nombre libre no vacío; selecciona titular humano o mascota bajo autorización. | Eva |
| RF-09 / HU-09 | 3.4 | Cargar foto JPG/PNG o PDF, título, descripción y vencimiento opcional. Reemplazar, consultar, descargar y eliminar propio; miembro activo lee compartido del grupo. | Eva |
| RF-10 / HU-10 | 3.4 | Categorías orientativas: identidad/cívico, estado civil/cierre de vida, seguridad social/laboral/tributario, salud. Alergias, consultas, recetas y vacunas se registran como documentos/notas con autor y fechas. | Eva |
| RF-11 / HU-11 | 3.5 | Cualquier miembro crea varias hojas propias, elige grupo al crearlas y nombre; otros miembros no acceden a sus finanzas por defecto. CRUD del titular. | Waldir |
| RF-12 / HU-12 | 3.5 | CRUD categorías por hoja, nombre, descripción y tipo ingreso/egreso. Categoría usada no se borra ni cambia de tipo hasta reasignar movimientos. | Waldir |
| RF-13 / HU-13 | 3.5 | Año buscable 1-9999, doce columnas mensuales, CRUD de múltiples ingresos/egresos por mes con categoría del mismo tipo/hoja, monto positivo y descripción. | Waldir |
| RF-14 / HU-14 | 3.5 | Totales ingreso, egreso y saldo por mes y año; déficit/superávit/equilibrio explícitos. Aislar por hoja y año; usar enteros en centavos BOB, sin coma flotante. | Waldir |
| RF-15 / HU-15 | 3.5 | Descargar CSV por hoja y año, UTF-8, escapado de comillas/comas/saltos y fórmulas de planilla neutralizadas. Encabezados y totales de los doce meses. | Waldir |

## Aclaraciones de producto propuestas

- El CRUD de admin se limita a su grupo, membresías, parentescos, mascotas y moderación de documentos compartidos. No permite cambiar contraseñas, perfil privado, ni presupuesto personal de otros.
- Los datos CI, domicilio, nacimiento y salud permanecen privados al titular hasta compartir de manera explícita en un grupo. Un ID público buscable no revela esos datos. Registrar consentimiento al compartir y mostrar el grupo destino antes de subir.
- La misma persona puede ser padre en un grupo y miembro sin admin en otro. Los documentos se comparten separadamente por grupo; no hay acceso transitivo entre grupos.
- Al salir o ser expulsado: revocar acceso a documentos del grupo y a sus hojas vinculadas; el titular puede exportar antes de salir. No borrar datos silenciosamente. Reingreso no restaura privilegios administrativos.
- Los documentos que un titular subió se retiran del grupo al salir; se conserva solo auditoría mínima sin contenido sensible. Borrado de archivos mediante tarea reintentable, sin huérfanos públicos.
- Parentescos derivados como primo/tío se calculan de enlaces base; si el usuario agrega una etiqueta social, no inventar ascendencia biológica. Admitir adopción y familias ensambladas sin suposiciones de género.
- Representación de personas sin cuenta o fallecidas y perfiles de menores quedan como cambio de alcance pendiente de validación docente; no registrar cuentas de mascotas.
- No hay alertas de vencimiento ni importación OCR obligatorias en esta versión. El vencimiento se muestra; no elimina el documento.

## Casos de uso

| CU | Actor y precondición | Flujo principal | Alternos / resultado |
|---|---|---|---|
| CU-01 Cuenta | Visitante | Registra datos, verifica email y entra | Duplicado/fecha futura/credenciales erróneas; mensaje sin enumerar cuentas |
| CU-02 Familia | Usuario autenticado | Crea grupo y aparece como admin | Nombre inválido; ningún grupo externo visible |
| CU-03 Invitación | Admin activo | Busca ID exacto, invita; receptor acepta | ID inexistente genérico, rechazo, caducidad, revocación; no acceso prematuro |
| CU-04 Roles/salida | Miembro activo | Admin transfiere; miembro sale | Último admin bloqueado y transacción revertida |
| CU-05 Parentesco | Admin | Elige dos miembros, relación y guarda | Ciclo o grupo distinto rechazado |
| CU-06 Mascota | Admin | Crea tarjeta, edita y elimina | Usuario normal no puede escribir; comprobar que RLS/RPC no modifica datos |
| CU-07 Archivo | Miembro/titular | Crea carpeta propia, consiente compartir, sube archivo y familiar lo consulta | Tipo/tamaño/firma inválidos, malware o grupo externo: no publicación |
| CU-08 Presupuesto | Miembro/titular | Crea hoja, categoría, movimientos y ve saldo | Monto/mes/año/categoría inválidos; no cambios parciales |
| CU-09 Exportación | Titular | Elige año y descarga CSV | Sin sesión/hoja ajena: denegado; año vacío genera doce meses en cero |

## No funcionales y objetivos de aceptación

RNF-01: autorización en cada consulta/escritura y archivo, pruebas negativas multiusuario y multigrupo obligatorias. RNF-02: HTTPS en despliegue, secretos fuera de Git y cifrado de almacenamiento/backups. RNF-03: lectores de pantalla, contraste AA, texto ampliado 200%, controles de al menos 48 dp y mensajes comprensibles. RNF-04: p95 de API < 800 ms con 20 usuarios y 1.000 movimientos por hoja en staging (objetivo, no medición actual). RNF-05: errores de red/reintentos sin duplicar movimientos; transacciones e idempotencia. RNF-06: backup diario y ensayo de restauración; RPO 24 h/RTO 4 h propuestos. RNF-07: matriz Android físico/emulador y iOS en macOS; estados sin red y regreso de segundo plano. RNF-08: todos los cambios trazables a HU, prueba, issue y PR.
