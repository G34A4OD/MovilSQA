# Edge Functions

Solo para operaciones que requieren entorno confiable. Ver contrato. Verificar JWT, autorizar cada recurso y usar secret/service_role solo en el paso privilegiado inevitable. Secretos de Supabase/escáner nunca en Flutter.

| Función | Estado |
|---|---|
| `lookup-user` | Desplegada (identidad/familia) |
| `process-document` | HU-09: valida bytes reales; sin `NIDO_DOCUMENT_SCANNER` operativo permanece en cuarentena |
| `delete-account` | Pendiente |

`NIDO_DOCUMENT_SCANNER=off` (default) o ausente → `scanner_unavailable`. `simulate` solo para evidencia de pruebas, no es escáner de producción.
