# Eva · Documentos, privacidad y automatización

**Primero únete al repositorio:** https://github.com/G34A4OD/MovilSQA. Envía tu handle a Gerardo para que te invite como colaboradora y acepta la invitación con tu propia cuenta. Clonar un repositorio público no da permiso de push. Si recibes 403, revisa cuenta/invitación; no uses credenciales de Gerardo.

## Tu participación y entregables

Implementas HU-08..10 de punta a punta: Flutter, API Laravel, DB, archivos privados y pruebas. Eres QA Champion de herramientas/reportes; tu aporte incluye desarrollo. Gerardo revisa tus PR; tú revisas los de Waldir.

| Orden | Trabajo | Evidencias |
|---|---|---|
| E1 | Carpetas por grupo/titular y CRUD | HU-08, TC-DOC-01 y negativos API |
| E2 | Carga, edición, vencimiento y descarga privada JPG/PNG/PDF | HU-09, TC-DOC-02..04 |
| E3 | Salud/notas/categorías orientativas y mascota | HU-10, permisos/consentimiento y datos ficticios |
| E4 | Comparar herramientas: 4 web + 4 móvil, 3 abiertas/1 comercial cada matriz | Word/Excel + presentación breve + flujo CI, Clase XIX |
| E5 | E2E Android, fallos/capturas, exploración, accesibilidad y auditoría | Reporte Clase XX, validaciones humanas reales |

Divide la carga de archivos en issues pequeños por su riesgo. Puedes avanzar UI/dominio/fixtures sobre contrato mientras Gerardo integra servidor. No incorporar permisos abiertos para avanzar.

## Tus rutas

app/lib/features/documents/**, app/test/documents/**, web/app/Modules/Documents/**, web/routes/modules/documents.php, migraciones orden 000300 y web/tests/Feature/Documents/**. Custodias docs/sqa/HERRAMIENTAS.md y tus reportes/auditorías. Cada ejecución tiene ID único. Core/main/dependencias/locks/CI/rutas agregadoras se coordinan con Gerardo mediante PR previo.

## Prompt inicial para tu agente

~~~text
Trabajas conmigo, Eva, en Nido del equipo Gerardo/Eva/Waldir. Primero comprueba que MI propia cuenta haya aceptado la invitación como colaboradora de https://github.com/G34A4OD/MovilSQA. Si falta, explícame que Gerardo debe invitar mi handle y continúa diseño/testware local. No usar credenciales ajenas ni inventar autoría.

Lee AGENTS.md, README.md, docs/ESTADO.md, docs/REQUISITOS.md, docs/ARQUITECTURA.md, docs/SEGURIDAD.md, docs/SUPABASE.md, docs/api/CONTRATO.md, docs/sqa/TEST_PLAN.md, docs/sqa/CASOS_PRUEBA.md, docs/COLABORACION.md y equipo/EVA.md. Revisa los PDF del curso si existen localmente; si no, docs/FUENTES.md. Verifica git status y preserva cambios ajenos. No generes otra app ni dupliques identidad/presupuesto.

Mi módulo vertical es documentos HU-08..10 con Flutter Material 3, ViewModel/repositorio, API Laravel/PostgreSQL conforme al contrato. Una issue real por rama desde origin/develop; commits míos; PR a develop revisado por Gerardo. No reescribir core/main/pubspec/locks/CI/contrato ni rutas agregadoras en paralelo; pedir PR previo de cambios.

Implementa carpetas propias por grupo con CRUD, documentos con título/descripción/vencimiento opcional y foto JPG/PNG o PDF. Consentimiento al compartir; miembro activo lee compartido, titular escribe y admin modera con auditoría. Admin no edita perfil privado. Mascota no tiene cuenta; admin autorizado administra sus documentos. Resolver permisos desde carpeta/propietario en servidor, no confiar en family_id enviado.

Archivo privado: 10 MiB máximo, extensión/MIME/firma reales en servidor, UUID de nombre, cuarentena/escaneo y compensación/limpieza si falla una fase. Un header válido no demuestra archivo seguro. Si escáner falta, mantener cuarentena sin publicar. Descarga por controlador autenticado que reautoriza cada petición y Cache-Control no-store; no URL pública o reutilizable larga que sobreviva expulsión. No storage:link para documentos familiares.

Tests con grupo A/B, invitado pendiente, expulsado, token revocado, IDs manipulados y carga adversa. No usar CI/health/docs reales ni tokens en Git/log/capturas. Escribir unidad/widget/API y E2E integrado Android, registrar entorno/build/commit/TC/HU, duración/resultados, stack/log y captura exacta de fallos UI. No afirmar pruebas de dispositivo por tener widget tests.

Completa Clase XIX: matriz de al menos tres herramientas abiertas y una comercial para web y para móvil, fuentes oficiales y decisión técnica. Exporta a Word/Excel y crea presentación breve con piloto y diagrama de CI. integration_test es primera opción Flutter; Appium requiere piloto de compatibilidad. Selenium web no prueba APK; Detox para React Native no es adopción automática Flutter. Confirmar con docente si exige herramienta concreta.

Al terminar cada historia, ejecuta validación, actualiza trazabilidad/evidencias/Planner y abre PR pequeño para Gerardo con Closes #REAL. Yo reviso PR de Waldir con pruebas reales desde mi cuenta. No simules aprobación, firma, coautoría ni resultado. Reporta implementación, pruebas y bloqueos concretos; conserva el trabajo independiente autorizado.
~~~

## Prompt para revisión de Waldir

~~~text
Actúa como agente de Eva para revisar el PR de Waldir indicado. Lee diff, HU y TC; trae rama sin perder mis cambios, ejecuta las pruebas y valida categorías, varios movimientos, años/meses, totales y CSV con comillas/comas/fórmulas. Comprueba que admin no vea hojas personales ajenas. Con la autorización de esta revisión, comenta desde mi cuenta commit/entorno/pasos/resultado/evidencia; si falla, solicita cambios concretos y bug trazable. No apruebes sin probar ni desde cuenta del autor.
~~~

## Cierre personal

PR propio de funcionalidad + tests + revisión a Waldir + matriz/presentación + auditoría con acciones verificadas + capturas Android + tarea Planner. Reporte de Clase XX: información general, detalle, evidencia, observaciones, conclusiones y firmas solo tras revisión real.


## Decisión de infraestructura confirmada

Supabase aloja PostgreSQL y Storage privado; la app consume API Laravel del stack del curso. Sanctum gestiona cuentas/sesión sin duplicarlas en Supabase Auth. Leer docs/SUPABASE.md; secretos de servidor nunca en Flutter, Git o chats. La conexión real necesita proyecto de pruebas y configuración local.

## Issues reales iniciales

- [HU-08 · #9](https://github.com/G34A4OD/MovilSQA/issues/9) · EDT 3.4 · S2 - Familia y archivos
- [HU-09 · #10](https://github.com/G34A4OD/MovilSQA/issues/10) · EDT 3.4 · S2 - Familia y archivos
- [HU-10 · #11](https://github.com/G34A4OD/MovilSQA/issues/11) · EDT 3.4 · S3 - Presupuesto e integración
- [QA-01 · #17](https://github.com/G34A4OD/MovilSQA/issues/17) · EDT 4.1 · S1 - Base e identidad
- [QA-02 · #18](https://github.com/G34A4OD/MovilSQA/issues/18) · EDT 4.2 · S4 - Calidad y entrega

Cuenta identificada: **pizzatoev**. Invitación Write enviada; aceptar antes de push.
