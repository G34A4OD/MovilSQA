# Eva · Documentos, privacidad y automatización

**Primero únete al repositorio:** https://github.com/G34A4OD/MovilSQA. Tu cuenta identificada es **pizzatoev** y se envió una invitación Write. Acepta la invitación con tu propia cuenta antes de push/revisión. Clonar un repositorio público no da permiso de escritura. Si recibes 403, comprueba cuenta/invitación; no uses credenciales de Gerardo.

## Enfoque confirmado

El producto es una app Flutter + **Supabase directo**. El cliente usa `supabase_flutter` con Supabase Auth, datos protegidos por RLS y Storage privado. Las operaciones que necesitan confianza o transacción se implementan mediante RPC SQL y, cuando corresponda, Edge Functions. El alcance actual no incluye otra aplicación ni una API propia.

La base todavía es una demo en memoria. Las políticas, la carga privada, el escaneo y la integración Auth/Storage se deben implementar y demostrar; no están garantizados por las pantallas de ejemplo.

## Tu participación y entregables

Implementas HU-08..10 de punta a punta: Flutter, carpetas/metadatos/RLS, archivos privados y pruebas. Eres QA Champion de herramientas/reportes y también desarrolladora. Gerardo revisa tus PR; tú revisas los de Waldir.

| Orden | Trabajo | Evidencias |
|---|---|---|
| E1 | Carpetas por grupo/titular y CRUD seguro | HU-08, TC-DOC-01 y acceso negativo directo con SDK/REST de Supabase |
| E2 | Carga, edición, vencimiento y lectura privada JPG/PNG/PDF | HU-09, TC-DOC-02..04; cuarentena y validación confiable |
| E3 | Salud/notas, organización orientativa y mascota | HU-10, RLS, consentimiento, moderación auditada y fixtures sintéticos |
| E4 | Comparación de herramientas y presentación de decisión para el producto móvil | Matriz Word/Excel, tres opciones abiertas/una comercial, fuentes y flujo CI; comparación de otros entornos solo si la actividad la solicita |
| E5 | E2E Android, fallos/capturas, exploración, accesibilidad y auditoría | Reporte Clase XX y validaciones humanas reales |

Divide la carga de archivos en issues pequeños por su riesgo. Puedes avanzar UI/dominio/fixtures sobre el contrato mientras se publica la infraestructura compartida. No abrir acceso público ni desactivar RLS para avanzar.

## Tus rutas

- Flutter: `app/lib/features/documents/**` y `app/test/documents/**`.
- Datos: archivos propios en `supabase/migrations/`, lote inicial reservado `202611140003xx_*` (xx segundos 00-59; ejemplo válido `20261114000300_documents_base.sql`), sin duplicar versiones ni editar migraciones ya aplicadas.
- Pruebas: `supabase/tests/documents/**`, con SQL/pgTAP y pruebas de integración Storage con usuarios de pruebas.
- Edge Function del contrato: `supabase/functions/process-document/**`. Si se necesita el fallback de lectura de bytes, acordar nombre/firma en el contrato antes de crearlo. Configuración/secretos compartidos mediante coordinación con Gerardo.
- Documentación propia: `docs/sqa/HERRAMIENTAS.md`, reportes y auditorías de tus inspecciones. Cada ejecución tiene ID único.

Gerardo custodia core/main/dependencias/locks/configuración Supabase/CI/contrato. Solicita cambios mediante PR previo pequeño. Usa nombres de tablas, buckets, rutas lógicas y RPC exactos de `docs/api/CONTRATO.md`; no decidir una segunda convención en tu módulo. No crear una migración común enorme que también modifique identidad o presupuesto.

## Seguridad documental en Supabase

La URL y clave publishable/anon pueden estar en Flutter; la seguridad depende de RLS/grants y las políticas de `storage.objects`. Las claves secret/service_role y las credenciales del escáner quedan solo en entornos confiables; nunca en el cliente ni en evidencias. Las pruebas normales usan JWT de usuarios de pruebas, porque service_role puede saltar RLS.

Una carpeta pertenece a un grupo y a un titular humano o mascota. La pertenencia vigente y el propietario se comprueban en datos/Storage para cada operación; no confiar en family_id, owner_id o ruta enviados desde Flutter. Miembros activos leen compartido, titular escribe y admin modera con auditoría según el contrato; no concede acceso al perfil privado ni finanzas ajenas.

La carga inicial va a cuarentena privada: máximo 10 MiB y PDF/JPG/PNG. Validar extensión/MIME/firma y contenido en un proceso confiable, con nombre opaco y prevención de rutas manipuladas. La validación Dart solo da feedback. Supabase Storage no equivale a un escáner antimalware configurado: implementar la función/proceso de validación y escaneo del contrato. Si no está operativo, mantener cuarentena y no publicar. Probar limpieza compensatoria y objetos huérfanos al fallar carga/publicación.

La lectura de bytes requiere autorización vigente, no una convención del cliente. Conforme al contrato, restringir SELECT de storage.objects por operación mediante storage.allow_any_operation a object.get_authenticated y object.get_authenticated_info, además de documento approved, consentimiento, grupo y sesión viva. No permitir firma/listado por otra policy permisiva. Probar desde un cliente adverso la llamada directa createSignedUrl: debe ser denegada aunque el usuario pueda descargar de manera autenticada. Si el proyecto no soporta los helpers/operaciones necesarios, negar SELECT Storage directo al móvil y leer mediante Edge autenticada que autorice metadata/sesión y devuelva bytes, nunca una URL firmada. No basta con omitir el método en la UI: una URL firmada ya emitida puede reutilizarse hasta expirar. Revocar membresía/sesión debe bloquear nuevas descargas; una copia ya guardada no se recupera remotamente.

No asumir que logout invalida criptográficamente un access JWT. Para metadata y bytes sensibles es obligatorio usar private.has_live_session() del contrato, que contrasta session_id con auth.sessions mediante helper privado custodiado por Gerardo; el móvil no lee auth.sessions. Añadir el control de sesión a RLS/RPC/Storage y al fallback Edge según contrato. Probar sesión viva, luego signOut con scope documentado y el mismo JWT todavía no expirado: ya no debe permitir leer filas/bytes ni mutar datos sensibles. Registrar resultados sin token; probar aparte salida/expulsión con membresía revocada. No guardar contenido sensible en caches persistentes ni mostrarlo al cambiar de cuenta.

Configuración cliente prevista: `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`; usar la inicialización `publishableKey` de la versión fijada del SDK. `anonKey` queda como alternativa heredada si el contrato lo documenta. La plantilla `app/config/supabase.example.json` solo describe valores públicos y todavía no conecta la demo; seguir `supabase/README.md` antes de inicializar el SDK.

## Prompt inicial para tu agente

~~~text
Trabajas conmigo, Eva, en Nido del equipo Gerardo/Eva/Waldir. Primero comprueba que MI propia cuenta pizzatoev haya aceptado invitación como colaboradora de https://github.com/G34A4OD/MovilSQA. Si falta, indícame que debo aceptar la invitación o que Gerardo revise el acceso y continúa diseño/testware local. No usar credenciales ajenas ni inventar autoría.

Lee AGENTS.md, README.md, docs/ESTADO.md, docs/REQUISITOS.md, docs/ARQUITECTURA.md, docs/SEGURIDAD.md, docs/SUPABASE.md, docs/api/CONTRATO.md, docs/sqa/TEST_PLAN.md, docs/sqa/CASOS_PRUEBA.md, docs/COLABORACION.md y equipo/EVA.md. Los PDF locales orientan SQA; el usuario confirmó que el stack de otro proyecto no aplica a este producto móvil. Si faltan fuentes, usa docs/FUENTES.md sin inventar contenido. Revisa git status y preserva cambios ajenos.

Mi módulo es documentos HU-08..10: Flutter Material 3, ViewModel/repositorio y supabase_flutter para datos/RPC/Storage, con Auth y RLS. No crear otra app ni una API propia. Una issue real por rama desde origin/develop y PR a develop para Gerardo. No reescribir core/main/pubspec/locks/config/CI/contrato en paralelo: pedir PR previo. Usa las tablas, buckets y funciones de docs/api/CONTRATO.md y mi lote de migraciones; no editar migraciones aplicadas ni tocar módulos de compañeros.

Implementa carpetas propias por grupo con CRUD, título/descripción y vencimiento opcional de documentos PDF/JPG/PNG. Consentimiento al compartir; miembro activo lee compartido, titular escribe y admin modera con auditoría. Mascota sin cuenta y sus documentos bajo admin autorizado. Perfil privado no editable por admin del grupo. Las políticas RLS/Storage y RPC comprueban auth.uid(), membresía vigente y titularidad; sustituir IDs o rutas en un cliente modificado no permite acceso.

URL y clave publishable/anon pueden ir en configuración Flutter. Secret/service_role, contraseña DB y secretos de escaneo nunca van al cliente, Git o prompts. No demostrar permisos usando solo service_role, porque puede saltar RLS.

Subida a cuarentena privada con 10 MiB máximo, nombre opaco y validación de extensión/MIME/firma/contenido en Edge Function/proceso confiable del contrato. La verificación Dart no sustituye el control del backend ni garantiza archivo seguro. Supabase no implica un antimalware ya conectado; si escaneo/validación no existe, conservar cuarentena sin publicar y reportar esa limitación. Estado approved solo lo cambia el proceso autorizado. Compensar fallos y probar limpieza de archivos huérfanos.

Lectura conforme al contrato: SELECT de storage.objects limitado por storage.allow_any_operation a object.get_authenticated/object.get_authenticated_info y checks de sesión/documento/consentimiento/grupo. Exigir test adverso que llame createSignedUrl directamente con el JWT del miembro: debe fallar; ocultarlo en UI no es control de seguridad. No abrir otra policy que permita firma/listado. Verificar disponibilidad de los helpers en el proyecto; si no hay separación por operación, negar SELECT Storage directo al móvil y usar la Edge autenticada del contrato que autorice y devuelva bytes, sin generar URLs firmadas. Una URL firmada ya emitida dura hasta expirar; copias descargadas deliberadamente quedan fuera de revocación. Implementar obligatoriamente private.has_live_session() en las políticas/funciones sensibles según el contrato, con session_id contrastado con auth.sessions por helper privado y grants de Gerardo, sin acceso directo del cliente a auth.sessions. Probar sesión viva, capturar JWT sin loguearlo, ejecutar signOut con scope documentado y reutilizar el JWT aún no expirado: no debe leer filas/bytes ni efectuar mutaciones sensibles. Probar aparte salida/expulsión por membresía revocada y limpiar sesión/caches.

Tests positivos/negativos con grupo A/B, invitado pendiente, expulsado, usuario normal/admin/propietario, IDs/rutas manipulados y carga adversa. Solo datos ficticios; sin documentos reales, salud, tokens o secretos en logs/capturas. Escribir unidad/widget, SQL/pgTAP para RLS/restricciones/RPC e integración real con Storage y cuentas Auth de pruebas; E2E Android al existir integración. Registrar TC/HU, commit/build/entorno/duración/resultados, logs/stack y captura del fallo UI. Los tests de datos/dispositivo no están ejecutados hasta tener evidencia; widget tests no son prueba Android.

Completa la selección Clase XIX para el producto móvil: al menos tres opciones abiertas y una comercial, fuentes oficiales, criterios, matriz Word/Excel y presentación breve con piloto/flujo CI. Si se pide comparación de otro entorno como ejercicio académico, incluirla sin agregar un producto al alcance. integration_test es base Flutter; Appium requiere piloto de compatibilidad. No afirmar un piloto ejecutado ni adquirir licencias sin autorización.

Al terminar cada historia, ejecuta validación, actualiza trazabilidad/evidencias/GitHub Projects y abre PR pequeño para Gerardo con Closes #REAL. Yo reviso PR de Waldir desde mi cuenta con pruebas reales. No simules aprobación, firma, coautoría ni resultado. Reporta implementación, pruebas y bloqueos concretos; conserva avance independiente autorizado.
~~~

## Prompt para revisión de Waldir

~~~text
Actúa como agente de Eva para revisar el PR de Waldir indicado. Lee diff/HU/TC/contrato Supabase; trae la rama sin perder mis cambios. Ejecuta pruebas y valida categorías, varios movimientos, años/meses, totales y CSV con comillas/comas/saltos/fórmulas. Comprueba con JWT de dos usuarios de pruebas que RLS/RPC impiden ver o exportar hojas ajenas, incluso siendo admin de familia. Con autorización de esta revisión, comenta desde mi cuenta commit/entorno/pasos/resultado/evidencia; solicita cambios y bug trazable si falla. No apruebes sin probar ni desde cuenta del autor.
~~~

## Cierre personal

PR propio de funcionalidad + tests de datos/Storage/Flutter + revisión a Waldir + matriz/presentación + auditoría con acciones verificadas + capturas Android + tarea GitHub Projects. Reporte Clase XX: información general, detalle, evidencia, observaciones, conclusiones y firmas solo tras revisión real.

## Issues reales iniciales

- [HU-08 · #9](https://github.com/G34A4OD/MovilSQA/issues/9) · EDT 3.4 · S2 - Familia y archivos
- [HU-09 · #10](https://github.com/G34A4OD/MovilSQA/issues/10) · EDT 3.4 · S2 - Familia y archivos
- [HU-10 · #11](https://github.com/G34A4OD/MovilSQA/issues/11) · EDT 3.4 · S3 - Presupuesto e integración
- [QA-01 · #17](https://github.com/G34A4OD/MovilSQA/issues/17) · EDT 4.1 · S1 - Base e identidad
- [QA-02 · #18](https://github.com/G34A4OD/MovilSQA/issues/18) · EDT 4.2 · S4 - Calidad y entrega

Cuenta identificada: **pizzatoev**. Invitación Write enviada; aceptar antes de push.
