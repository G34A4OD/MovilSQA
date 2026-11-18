# Nido · Archivo y presupuesto familiar

Proyecto móvil de SQA de **Gerardo, Eva y Waldir**. **Flutter + Supabase directo**: Auth para cuentas, PostgreSQL con RLS para datos, Storage privado para archivos y funciones SQL/RPC para reglas transaccionales. Producto único móvil con Material 3 en español. [Configuración de Supabase](docs/SUPABASE.md).

## Empieza aquí

1. Lee [el estado real](docs/ESTADO.md), [el alcance](docs/REQUISITOS.md) y [el plan SQA](docs/sqa/TEST_PLAN.md).
2. Cada integrante usa su cuenta de GitHub, acepta la invitación a [MovilSQA](https://github.com/G34A4OD/MovilSQA) y trabaja con su guía:
   - [Gerardo](equipo/GERARDO.md): identidad, grupos, parentescos, seguridad transversal e integración.
   - [Eva](equipo/EVA.md): carpetas, documentos, archivos privados, automatización y reporte.
   - [Waldir](equipo/WALDIR.md): presupuesto, categorías, movimientos, CSV y métricas.
3. Sigue [el flujo GitHub y GitHub Projects](docs/COLABORACION.md). La rama compartida de integración será `develop`; `main` se reserva para releases revisados.

La preparación está en el [PR #21](https://github.com/G34A4OD/MovilSQA/pull/21). Hasta su revisión e integración, obtenerla con gh pr checkout 21 después de aceptar la invitación. Las nuevas historias salen de develop cuando la base esté integrada.

## Ejecutar la base móvil

Se conserva el proyecto existente en `app/`. Versión validada: Flutter 3.41.9 / Dart 3.11.5.

```powershell
cd app
flutter pub get
flutter run
```

La compilación normal se conecta por HTTPS al proyecto de pruebas compartido `nido-dev`. En cada teléfono, inicia sesión con una cuenta propia, completa el perfil y comparte el ID de invitación con el administrador del grupo. Usa únicamente datos ficticios en este entorno.

```powershell
flutter run
# APK de pruebas Android conectada, para instalar en otros teléfonos:
flutter build apk --debug
# Alternativa explícita sin red, solo demostración ficticia:
flutter run --dart-define=NIDO_DEMO=true
```

Si necesitas otro proyecto o Supabase local, copia `config/supabase.example.json` a `config/supabase.local.json` e indica ambas variables con `--dart-define-from-file=config/supabase.local.json`. Nunca incluir service_role, claves secretas ni contraseña DB. Consultar [integración y revisión](docs/INTEGRACION.md).

```powershell
# Desde la raíz; genera evidencia con fecha, entorno, casos y métricas.
./scripts/verify.ps1
```

## Organización

| Ruta | Contenido |
|---|---|
| `app/lib/core/` | Dinero, validaciones y tema compartidos |
| `app/lib/features/` | Módulos por funcionalidad, con dominio/presentación |
| `supabase/` | Siete migraciones identity/family, pruebas SQL/RLS, entorno local y Edge lookup-user |
| `app/config/` | Plantilla pública de conexión; configuración real local ignorada, sin claves elevadas |
| `docs/api/` | Contrato del SDK Supabase, tablas, permisos y RPC para trabajar en paralelo |
| `docs/sqa/` | Test Plan, casos, trazabilidad, auditoría y herramientas |
| `planificacion/` | Backlog, EDT, estimaciones y cálculo reproducible PERT/CPM |
| `.github/` | CI, plantillas de issue y PR |
| `evidencias/` | Índice de entrega y resultados reales |

Los PDF del curso permanecen en la carpeta local y se excluyen del repositorio. Sus páginas de referencia se registran en [FUENTES.md](docs/FUENTES.md).

## Situación de GitHub

GitHub CLI autorizado; issues reales, cuatro milestones, `develop` como default y `main`/`develop` protegidas. Eva (`pizzatoev`) y Waldir (`riblawaldir`) aceptaron Write; sus issues ya están asignadas. Ver [estado remoto](docs/GITHUB_ESTADO.md) y [flujo de colaboración](docs/COLABORACION.md). La base se entrega por PR para revisión independiente; todavía no hay release final. No guardar tokens ni contraseñas en archivos o chats.

## Tablero de trabajo

[GitHub Projects · MovilSQA](https://github.com/users/G34A4OD/projects/1/views/1): 21 issues vinculadas, incluido G0 #22, con responsable y revisión. Filtrar por Responsable o Assignees. PREP/G0/HU-01..07 están en revisión y OPS-01 en curso; las tareas de Eva/Waldir conservan el estado de trabajo real que registren sus agentes. No se necesitan cuentas Microsoft 365.
