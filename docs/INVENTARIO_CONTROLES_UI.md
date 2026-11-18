# Inventario de controles de Nido

Revisión estática de `feature/rediseno-ui`, 18/11/2026. **OK por código** significa que el callback visible está conectado a la acción descrita; no acredita ejecución en un dispositivo ni el backend. Los controles agrupados comparten pantalla y propósito. Los campos editables y selectores se incluyen. Los controles se deshabilitan durante operaciones `busy` y, cuando corresponde, según rol, validez o caducidad. Las líneas son referencias al código de esta revisión.

| Modo / pantalla y control | Archivo:línea | Acción esperada | Acción real según código | Estado |
|---|---|---|---|---|
| Demo / barra superior: avatar | `app/lib/main.dart:125` | Abrir la familia de ejemplo | Antes no tenía acción aunque parecía un botón; ahora abre Familia (tooltip «Ver mi familia») | Corregido; probado en dispositivo y widget test |
| Demo / navegación: Inicio, Familia, Presupuesto, Documentos | `app/lib/main.dart:211` | Cambiar pestaña | Cambia `section` | OK por código |
| Demo / Inicio: saldo | `app/lib/main.dart:275` | Abrir presupuesto | Selecciona presupuesto | OK por código |
| Demo / Inicio: tres accesos rápidos | `app/lib/main.dart:375` | Abrir Familia, Presupuesto o Documentos | Selecciona pestaña correspondiente | OK por código |
| Demo / Inicio: Casa Rivera y Archivo familiar | `app/lib/main.dart:395`, `:405` | Abrir familia o documentos | Selecciona pestaña | OK por código |
| Demo / Inicio: Conocer familia | `app/lib/main.dart:443` | Abrir familia | Selecciona Familia | OK por código |
| Demo / Familia: miembros, vínculos y mascota | `app/lib/main.dart` (`_FamilyPreview`) | Mostrar la familia | Listas informativas sin callback | No interactivo |
| Demo / Familia: copiar ID, Aceptar/Rechazar invitación, Enviar invitación | `app/lib/main.dart` (`_FamilyPreview`), `app/lib/demo/demo_family.dart` | Mostrar el flujo de unirse e invitar para presentaciones | Estado en memoria con datos ficticios (`DemoFamily`); no envía nada a otros dispositivos | Probado en dispositivo y widget test |
| Demo / Documentos: cuatro carpetas | `app/lib/main.dart` (`_DocumentsPreview`) | Mostrar carpetas | Tarjetas estáticas sin InkWell ni chevron | No interactivo |
| Demo / Presupuesto: Movimiento | `app/lib/features/budget/presentation/budget_page.dart:45` | Abrir formulario | Abre hoja para movimiento en memoria | OK por código |
| Demo / Presupuesto: anterior, año, siguiente | `app/lib/features/budget/presentation/budget_page.dart:623`, `:631`, `:644` | Cambiar/buscar año | Cambia año, límites 1 y 9999; abre diálogo | OK por código |
| Demo / Buscar año: campo, Cancelar, Ver año | `app/lib/features/budget/presentation/budget_page.dart:199`, `:212`, `:216` | Introducir y validar año o cancelar | Valida rango y cambia año o cierra | OK por código |
| Demo / Presupuesto: doce meses | `app/lib/features/budget/presentation/budget_page.dart:911` | Seleccionar mes | Actualiza mes del modelo | OK por código |
| Demo / Presupuesto: categorías y CSV | `app/lib/features/budget/presentation/budget_page.dart:83`, `:89` | Gestionar categorías / ver CSV | Abre diálogos; CSV es vista previa | OK por código |
| Demo / Movimiento: categoría, monto, descripción | `app/lib/features/budget/presentation/budget_page.dart:290`, `:304`, `:319`, `:339` | Completar datos | Selector y campos alimentan formulario | OK por código |
| Demo / Movimiento: Cancelar y Guardar | `app/lib/features/budget/presentation/budget_page.dart:348`, `:356` | Cerrar o validar y guardar | Cancela o valida monto y guarda en memoria | OK por código |
| Demo / Movimiento existente y eliminar | `app/lib/features/budget/presentation/budget_page.dart:168`, `:169` | Editar o confirmar eliminación | Abre formulario o confirmación y elimina en memoria | OK por código |
| Demo / Categorías: fila, eliminar, crear, cerrar | `app/lib/features/budget/presentation/budget_page.dart:432`, `:436`, `:450`, `:454` | Editar, eliminar, crear o cerrar | Abre formulario, elimina si permitido o cierra | OK por código |
| Demo / Categoría: tipo, nombre, descripción, Cancelar, Guardar | `app/lib/features/budget/presentation/budget_page.dart:501`, `:508`, `:515`, `:523`, `:527` | Elegir datos y validar | Actualiza tipo, valida y guarda o cancela | OK por código |
| Demo / CSV y aviso de categoría: Cerrar / Entendido | `app/lib/features/budget/presentation/budget_page.dart:596`, `:1236` | Cerrar diálogo | Cierra diálogo | OK por código |
| Conectado / Acceso: correo y contraseña | `app/lib/features/identity/presentation/auth_gate.dart:134`, `:164` | Introducir credenciales y enviar | Campos alimentan `submit`; envío condicionado por carga | OK por código |
| Conectado / Acceso: mostrar contraseña | `app/lib/features/identity/presentation/auth_gate.dart:184` | Alternar visibilidad | Cambia estado `hidden` | OK por código |
| Conectado / Acceso: recuperar, entrar, crear cuenta, volver, cancelar sesión | `app/lib/features/identity/presentation/auth_gate.dart:204`, `:223`, `:257`, `:277`, `:301` | Navegar entre modos y enviar | Cambia modo o llama modelo Auth; deshabilita mientras carga | OK por código |
| Conectado / Cuenta: cerrar sesión, reintentar, volver edición | `app/lib/features/identity/presentation/account_home.dart:65`, `:83`, `:99`, `:298` | Cerrar sesión, reintentar perfil o cancelar edición | Llama Auth, carga perfil o cambia estado | OK por código |
| Conectado / Cuenta: Mis familias, copiar ID, editar perfil | `app/lib/features/identity/presentation/account_home.dart:159`, `:223`, `:285` | Abrir familias, copiar ID o editar | Navega, copia al portapapeles con aviso o abre editor | OK por código; ID comprobado con widget test en familias |
| Conectado / Perfil: campos, fecha y sangre | `app/lib/features/identity/presentation/profile_editor.dart:129`, `:151` | Editar datos y seleccionar fecha/sangre | Campos y selector actualizan formulario; fecha comprueba `mounted` | Riesgo de controlador dispuesto corregido |
| Conectado / Perfil: Guardar | `app/lib/features/identity/presentation/profile_editor.dart:176` | Validar y guardar | Llama modelo y vuelve si tiene éxito y está montado | OK por código |
| Conectado / Familias: seleccionar, recargar, volver | `app/lib/features/family/presentation/family_page.dart:287`, `:524`, `:530` | Abrir familia, actualizar o regresar | Selecciona, recarga o vuelve | OK por código |
| Conectado / Familias vacías: copiar ID | `app/lib/features/family/presentation/family_page.dart:319` | Copiar ID disponible | Copia y muestra aviso si está montado | OK con widget test |
| Conectado / Familias: crear y diálogo nombre/Cancelar/Guardar | `app/lib/features/family/presentation/family_page.dart:48`, `:65`, `:69`, `:339` | Crear grupo válido o cancelar | Diálogo devuelve nombre y modelo valida/envía; bloqueado mientras ocupa | OK con widget test y fake |
| Conectado / Familia: editar nombre y eliminar | `app/lib/features/family/presentation/family_page.dart:421`, `:437`, `:84` | Editar o confirmar nombre y contraseña para eliminar | Ejecuta diálogo y modelo; eliminar reautentica | OK por código; requiere admin |
| Conectado / Privacidad: elegir campos, cancelar, confirmar | `app/lib/features/family/presentation/family_page.dart:182`, `:208`, `:222`, `:226`, `:494` | Elegir consentimiento | Carga opciones, guarda selección; comprueba montaje tras diálogo | Riesgo de operación tras desmontaje corregido |
| Conectado / Invitaciones: ID, búsqueda y envío | `app/lib/features/family/presentation/invitations_panel.dart:69`, `:86`, `:119` | Buscar ID exacto e invitar | Valida 32 hex, busca candidato, envía; evita operaciones ocupadas | OK con widget test y fake |
| Conectado / Invitaciones: actualizar, aceptar, rechazar, revocar | `app/lib/features/family/presentation/invitations_panel.dart:61`, `:180`, `:193`, `:208` | Refrescar o responder/revocar | Llama repositorio; deshabilita respuestas caducadas; comprueba montaje al volver | Riesgo de callback tras desmontaje corregido; aceptación/rechazo probados con fake |
| Conectado / Miembros: menú administración/quitar y salir | `app/lib/features/family/presentation/members_panel.dart:56`, `:123` | Confirmar cambio, expulsión o salida | Abre confirmación y llama modelo; permisos y último admin dependen de backend | OK por código; no probado conectado |
| Conectado / Vínculos: recargar, asignar, menú editar/quitar | `app/lib/features/family/presentation/relationships_panel.dart:70`, `:81`, `:103` | Gestionar vínculos | Llama modelo, limita a admin y dos miembros | OK por código |
| Conectado / Vínculo: persona, rol, familiar, cancelar, guardar | `app/lib/features/family/presentation/relationships_panel.dart:193`, `:206`, `:224`, `:237`, `:241` | Elegir relación y guardar | Selector, cancela o devuelve datos; impide misma persona | OK por código |
| Conectado / Mascotas: recargar, añadir, menú editar/quitar | `app/lib/features/family/presentation/pets_panel.dart:50`, `:103`, `:153` | Gestionar mascotas | Abre diálogos y llama modelo; solo admin edita | OK por código |
| Conectado / Mascota: campos, fecha, cancelar, guardar | `app/lib/features/family/presentation/pets_panel.dart:195`, `:246`, `:268`, `:272` | Editar y validar datos | Selector de fecha y formulario; comprueba montaje tras fecha | Riesgo de controlador dispuesto corregido |
| Conectado / Carpetas: recargar, buscar, limpiar | `app/lib/features/documents/presentation/folders_panel.dart:135`, `:151`, `:157` | Actualizar y filtrar | Recarga; muestra búsqueda cuando hay más de cuatro; filtra localmente | OK por código |
| Conectado / Carpetas: Nueva, menú renombrar/eliminar | `app/lib/features/documents/presentation/folders_panel.dart:201`, `:241` | Crear o gestionar carpeta | Abre diálogo, valida, llama modelo; menú según permisos | Crear y negativos probados con fake |
| Conectado / Carpeta: nombre, titular, mascota, Cancelar, Crear | `app/lib/features/documents/presentation/folders_panel.dart:286`, `:309`, `:336`, `:346`, `:351` | Introducir datos y guardar | Valida nombre/titular, devuelve input o cancela | OK con widget tests y fake |
| Conectado / Carpeta: renombrar, cancelar, guardar, confirmar eliminación | `app/lib/features/documents/presentation/folders_panel.dart:393`, `:413`, `:417`, `:90` | Cambiar nombre o confirmar borrado | Valida y devuelve nombre o confirma; llama modelo | OK con widget tests y fake |
| Conectado / Hojas: nombre, crear, renombrar, eliminar | `app/lib/features/budget/presentation/sheets_panel.dart:129`, `:144`, `:160`, `:176` | Gestionar hojas | Llama modelo y muestra diálogos; comprueba montaje tras operaciones | Riesgo de controlador/modelo dispuesto corregido |
| Conectado / Hojas: campo, Cancelar, Guardar/Eliminar | `app/lib/features/budget/presentation/sheets_panel.dart:63`, `:72`, `:82` | Devolver nombre o cancelar | Diálogo devuelve texto o null | OK por código |
| Ambos / Confirmaciones: cancelar y confirmar | `app/lib/core/widgets/dialogs.dart:34`, `:45` | Devolver decisión | Devuelve false o true | OK por código |
| Ambos / Secciones: recargar | `app/lib/core/widgets/surfaces.dart:308` | Actualizar datos | Ejecuta callback provisto; se deshabilita con busy | OK por código |

## Prueba manual en dispositivo (demo)

Huawei ELE-AL00, Android 10, modo `NIDO_DEMO`, tema oscuro del sistema, 18/11/2026. Controles tocados y resultado observado en pantalla:

- Avatar, tarjeta de saldo, tres accesos rápidos y las cuatro pestañas: abren la pantalla esperada.
- Presupuesto: año anterior y siguiente, diálogo «Buscar año» con Cancelar, gestión de categorías (aviso al eliminar una categoría con movimientos; validación de nombre vacío; crear y eliminar «Transporte»), vista previa CSV con desplazamiento horizontal, «Movimiento» (guardar 150), selección de mes en el gráfico, edición con Cancelar y eliminación con confirmación: funcionan.
- Corregido tras la prueba: el ícono de los diálogos `AlertDialog` se estiraba a todo el ancho (`DialogIcon`), la vista previa CSV no indicaba que se puede desplazar (barra visible) y el error de nombre de categoría no se limpiaba al escribir.
- No se probó el modo conectado: requiere configuración real de Supabase y cuentas de prueba.

## Límites de revisión

Los listados y formularios están dentro de scrollables; el presupuesto reserva espacio inferior para el FAB. La revisión estática no demuestra hit testing, ausencia de solapamiento ni accesibilidad a escalas concretas: requiere recorrido manual. El modo conectado requiere proyecto y cuentas de prueba reales; las pruebas con fakes no acreditan red, RLS ni persistencia. Los campos estándar de texto y selección admiten las acciones nativas del sistema.
