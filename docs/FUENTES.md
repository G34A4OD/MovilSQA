# Fuentes y decisiones

Los archivos fuente están en la raíz local, fuera del control de versiones por derechos de distribución. Se extrajo su texto y se revisaron visualmente las tablas del plan y de herramientas.

| Fuente local | Páginas relevantes | Aplicación |
|---|---|---|
| Plan SQA movil.pdf | 1-5; tablas en 3 y 4 | Ocho secciones del Test Plan, seis evidencias, rúbrica 25/20/20/15/20 |
| gitub para equipos en xp.pdf | 3-17, 20-21, 34-61; APK pp. 57-58 | EDT, PERT/CPM, GitHub Projects, Material 3, ramas, revisiones, issues, releases y CI. El stack y producto web del proyecto anterior no aplican por aclaración del usuario |
| Clase_XIX_SQA.pdf | 9-23 | Riesgo para automatizar, comparación de al menos cuatro herramientas, tres abiertas y una comercial, flujo y presentación |
| Clase _XX_SQA.pdf | 9-24, 26-30 | Metadatos, métricas, fallos, capturas, trazabilidad, conclusiones y validaciones del reporte |
| Clases I-VI | Conceptos, proceso y producto | Prevención, objetivos de calidad, riesgos, QA/QC |
| Clases VII-X | STLC, gestión y testware | Planificación, diseño, ejecución, cierre, configuración y trazabilidad |
| Clases XI-XIV | Caja blanca/negra, técnicas y niveles | Equivalencias, límites, decisiones, unidad, integración, aceptación, no funcionales |
| Clases XV-XVIII | Automatización, agilidad, inspecciones y TDD/BDD | Riesgo, ciclo incremental, inspección por pares y evidencias rojo/verde/refactor |
| Dinámica SQA “El código que llegó demasiado lejos”.pdf | Actividad completa | Control de alcance y cambios, prevención y responsabilidades compartidas |
| agile_testing_-_a_practical_guide_for_testers_and_agile_teams.pdf | Referencia de apoyo | Colaboración continua entre negocio, desarrollo y QA |
| Plan SQA_web.pdf | Contexto | No sustituye el plan móvil ni agrega un segundo producto web completo al alcance solicitado |

## Fuentes técnicas primarias consultadas

- [Guía de arquitectura Flutter](https://docs.flutter.dev/app-architecture/guide): separación UI/datos, ViewModel y repositorios.
- [Pruebas de integración Flutter](https://docs.flutter.dev/testing/integration-tests): validación en dispositivo con `integration_test`.
- [Supabase con Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter): SDK y configuración pública.
- [RLS PostgreSQL](https://supabase.com/docs/guides/database/postgres/row-level-security): permisos de datos desde clientes.
- [Storage privado](https://supabase.com/docs/guides/storage/security/access-control): autorización de objetos.
- [Funciones PostgreSQL](https://supabase.com/docs/guides/database/functions): RPC y permisos.
- [Sesiones Auth](https://supabase.com/docs/guides/auth/sessions): tokens y límites de revocación.
- [Pruebas SQL/pgTAP](https://supabase.com/docs/guides/local-development/testing/pgtap-extended): validación de infraestructura.
- [Appium](https://appium.io/docs/en/latest/): alternativa E2E multiplataforma.

El usuario aclaró que Laravel y el producto web de las diapositivas correspondían a otro proyecto. Esa restricción no aplica a esta entrega móvil. La decisión vigente es **Flutter + Supabase directo**, con Auth, PostgreSQL/RLS, Storage privado y RPC/Edge Functions donde se necesiten. Se conserva el flujo de calidad y colaboración del curso. Ver SUPABASE.md y api/CONTRATO.md. Esta decisión ya está autorizada; no requiere otra confirmación.

Cambio de herramienta autorizado: el equipo usa GitHub Projects (Project 1 de G34A4OD) como tablero de SQA. Se mantienen las prácticas de trazabilidad del material docente.
