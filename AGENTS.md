# Instrucciones del equipo Nido

Leer README, docs/ESTADO, REQUISITOS, ARQUITECTURA, SEGURIDAD, api/CONTRATO, sqa/TEST_PLAN y guía del integrante. El usuario tiene autoridad de alcance; los roles sugeridos no equivalen a participación o aprobaciones reales.

- Producto único móvil: Flutter en app, Supabase Auth/PostgreSQL/Storage consumidos directamente mediante supabase_flutter, Material 3. No crear API propia ni producto web.
- Una historia por rama/PR desde develop, número real de issue. No inventar autores, revisiones, resultados, firmas o tags finales.
- Gerardo custodia contratos/core/composición/dependencias/CI y configuración común Supabase; Eva documentos; Waldir presupuesto. Migraciones y pruebas SQL por módulo, RPC transaccionales para invariantes. Esta preparación inicial corresponde al rol integrador; coordinar archivos compartidos antes de trabajo paralelo.
- Solo datos ficticios en demo/tests. Secretos, PDF docentes y documentos reales fuera de Git.
- Autorización en Supabase con RLS, grants y RPC por grupo/propietario para tablas y archivos privados. Dominio Dart no es barrera de seguridad. Solo clave publishable (o anon heredada) en cliente, jamás secret/service_role. Auth es la única fuente de identidad.
- Centavos enteros; parentesco separado de admin; mínimo un admin por grupo.
- Pruebas críticas positivas/negativas con TC/HU. scripts/verify.ps1 genera reporte; RLS/SQL/RPC/Auth/Storage/E2E/dispositivo se registran por separado. No presumir que cerrar sesión invalida instantáneamente un JWT ya emitido; probar los controles adicionales del contrato.
- Reportar lo ejecutado y lo pendiente; conservar cambios ajenos y evitar fuerza/reseteos destructivos.
