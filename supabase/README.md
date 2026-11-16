# Infraestructura de Nido · Supabase directo

Esta carpeta reserva el lugar de migraciones PostgreSQL/RLS, pruebas y Edge Functions. **No hay un proyecto Supabase inicializado, políticas desplegadas ni funciones implementadas todavía.** El contrato está en [CONTRATO.md](../docs/api/CONTRATO.md); la preparación, en [SUPABASE.md](../docs/SUPABASE.md).

Flutter usa supabase_flutter para Auth, consultas protegidas por RLS, RPC y Storage privado. No se desarrolla un sitio web ni un servidor HTTP intermedio.

| Integrante | Rutas | Responsabilidad |
|---|---|---|
| Gerardo | migrations identity/family, tests identity/family, configuración común | Auth, perfiles/consentimientos, grupos/admins, relaciones/mascotas; RLS y RPC base |
| Eva | migrations documents, tests documents, functions de documentos | Carpetas, metadata, políticas Storage, cuarentena/escaneo y limpieza |
| Waldir | migrations budget, tests budget | Hojas/categorías/movimientos, RLS de propietario, RPC y totales |

Gerardo inicializa el proyecto local/CLI y el esquema común primero; cada módulo agrega migraciones nuevas y tests propios. Nombres reales de migración: timestamp válido generado por CLI y sufijo del módulo, con dependencias ordenadas. No editar una migración aplicada ni copiar un timestamp de ejemplo sin comprobar colisiones. Cada PR indica tablas/RPC/policies modificadas y se prueba sobre migraciones limpias.

## Próximas tareas

1. Configurar CLI oficial y entorno local de pruebas conforme a la versión elegida y fijada. Inicializar config.toml bajo una issue; esta documentación no lo reemplaza.
2. Crear migraciones y fixtures sintéticos, incluidos grants/revoke, RLS y permisos Storage. SQL de mantenimiento/administración nunca se ejecuta desde Flutter.
3. Usar RPC con auth.uid(), autorización y transacciones para invariantes. Una Edge Function con secret key también debe autorizar identidad y grupo.
4. Incorporar pgTAP/SQL y pruebas SDK con usuarios distintos. SELECT sin filas no basta para probar escritura denegada: verificar ausencia de efectos secundarios.
5. Publicar a staging tras revisión y negativos Auth/RLS/RPC/Storage. La suite CI actual solo valida Flutter y el reportador.

Nunca copiar SUPABASE_ACCESS_TOKEN, contraseñas DB o secret/service_role a la app, documentos, Git o capturas. No aplicar pruebas destructivas a producción.
