# API Laravel · implementación por módulos

Esta carpeta define el lugar del servidor del stack A. **No contiene todavía una API ejecutable.** Gerardo inicializa el esqueleto y publica el primer PR antes de que Eva y Waldir agreguen sus rutas/migraciones.

```powershell
# Desde la raíz; ejecutar una sola vez en la historia de infraestructura.
composer create-project laravel/laravel web-bootstrap "^13.0"
# Revisar el proyecto generado y trasladarlo aquí sin sobrescribir este README.
# Fijar composer.lock, PHP 8.4+ y Laravel probado en CI.
```

No ejecutar este comando encima del trabajo de otro integrante. Leer docs/SUPABASE.md: PostgreSQL y Storage privado en Supabase, sin acceso directo desde Flutter. Configurar PostgreSQL, `php artisan install:api` (Sanctum), `.env.example`, migraciones y pruebas. Instalar con la versión documentada y confirmar soporte real antes de integrar. En desarrollo, Android emulador usa `10.0.2.2` para host local; producción exige HTTPS.

## Archivos exclusivos para cada módulo

| Responsable | Rutas Laravel / migraciones |
|---|---|
| Gerardo | `app/Modules/Identity/**`, `app/Modules/Family/**`, `routes/modules/identity.php`, `family.php`, migraciones `000100_*`, `000200_*` |
| Eva | `app/Modules/Documents/**`, `routes/modules/documents.php`, migraciones `000300_*` |
| Waldir | `app/Modules/Budget/**`, `routes/modules/budget.php`, migraciones `000400_*` |

Gerardo integra `routes/api.php` con los archivos por módulo. Usar fechas/timestamps de migración consistentes con el orden de dependencias, sin editar migraciones ya aplicadas. Tests por módulo en `tests/Feature/{Identity,Family,Documents,Budget}`. Factories compartidas en PR previo.

## Requisitos para el primer PR servidor

- GET health sin información sensible; estructura de errores de `docs/api/CONTRATO.md`.
- Autenticación Sanctum, validación, policies y DB PostgreSQL de tests separada.
- `composer install`, `composer validate --strict`, `php artisan test --log-junit=...` y formato pasan en CI.
- Sin endpoints permisivos temporales. Archivos privados y transacciones de último admin como gates de sus historias.
- `.env.example` solamente con valores ficticios. Ninguna credencial de base de datos en Flutter.
