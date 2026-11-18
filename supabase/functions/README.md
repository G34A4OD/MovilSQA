# Edge Functions

Solo para operaciones que requieren entorno confiable. Ver contrato. Verificar JWT, autorizar cada recurso y usar secret/service_role solo en el paso privilegiado inevitable. Secretos de Supabase/escáner nunca en Flutter.

| Función | Estado |
|---|---|
| `lookup-user` | Desplegada (identidad/familia) |
| `process-document` | HU-09: valida bytes reales; escaneo ClamAV/`http`; sin escáner operativo permanece en cuarentena |
| `download-document` | HU-09: descarga approved vía JWT + RPC; sin `createSignedUrl` (fallback sin SELECT Storage móvil) |
| `delete-account` | Pendiente |

`NIDO_DOCUMENT_SCANNER`: `off` (default) → `scanner_unavailable` y cuarentena. `clamav` usa clamd TCP (`NIDO_CLAMD_HOST`/`NIDO_CLAMD_PORT`, default `127.0.0.1:3310`). `http` POST a `NIDO_DOCUMENT_SCANNER_URL`. Solo `clamav`/`http` limpios publican y marcan `approved`. `simulate` está bloqueado en runtime (solo tests unitarios con `allowSimulate`); no publica.
