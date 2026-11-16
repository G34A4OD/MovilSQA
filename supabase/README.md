# Infraestructura de Nido · Supabase directo

Entorno CLI 3.1.0 inicializado. Siete migraciones identity/family aplicadas a nido-dev y reproducidas localmente; lookup-user desplegada. [Contrato](../docs/api/CONTRATO.md), [estado](../docs/ESTADO.md) y [comandos locales](LOCAL.md).

Gerardo mantiene Auth/perfil/grupos/admins/parentescos/mascotas y helpers comunes. Eva agrega documentos/Storage/cuarentena/escaneo; Waldir presupuesto/RPC/CSV. Cada módulo crea migraciones nuevas posteriores a sus dependencias y tests pgTAP propios en tests/database; no reescribir SQL aplicado.

RLS desde creación, escrituras críticas solo RPC, actor derivado de Auth y sesión vigente. private no está expuesto por Data API. lookup-user verifica JWT y llama la RPC con ese JWT; no usa service_role. Nunca distribuir claves elevadas ni contraseña DB en Flutter, Git o evidencias.

Documentos/Storage/presupuesto, delete-account y worker físico de cleanup_jobs siguen pendientes de integración. La cola retira acceso lógico; no acredita purga de archivos. No hay datos reales ni permisos globales como puente de desarrollo.

CI reproduce SQL/pgTAP, Auth/Edge/familia HTTP y concurrencia local. Restauración y Android real tienen scripts separados. No ejecutar reset ni scripts destructivos contra el entorno remoto.
