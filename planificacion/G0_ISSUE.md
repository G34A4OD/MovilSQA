# G0 · Base compartida Supabase y pruebas de autorización

Responsable: Gerardo. Revisor propuesto: Waldir (revisión humana pendiente).
Subtarea de #1. Fecha objetivo indicada por Gerardo: martes 17/11/2026.

## Alcance

- Configuración local reproducible con Supabase CLI y CI SQL.
- Esquema compartido de identidad/familia, permisos mínimos y helpers privados de sesión/membresía.
- Separación de perfil público mínimo y datos personales privados.
- Pruebas positivas/negativas con fixtures ficticios y roles authenticated/anon.
- Publicar infraestructura para que documentos y presupuesto agreguen sus migraciones sin abrir permisos globales.

## Aceptación

- [ ] Migraciones versionadas reproducibles en Supabase local.
- [ ] Sin escrituras directas que eludan RPC críticas ni lectura de auth.sessions.
- [ ] Guard de sesión distingue sesión vigente, ausente, ajena y revocada.
- [ ] Pruebas SQL y pipeline verificables; registrar limitaciones sin inventar resultados.
- [ ] PR pequeño revisable; depende del PR #21, no autorizar su propia integración.

Auth/UI y RPC de las historias HU-01..07 se entregan en PR posteriores. No incluye implementación de documentos o presupuesto.
