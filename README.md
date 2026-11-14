# Nido · Archivo y presupuesto familiar

Proyecto móvil de SQA de **Gerardo, Eva y Waldir**. Flutter + API Laravel + PostgreSQL y archivos privados en **Supabase**, combinando la elección del usuario con el stack A del curso. Interfaz Material 3 en español. [Configuración de Supabase](docs/SUPABASE.md).

## Empieza aquí

1. Lee [el estado real](docs/ESTADO.md), [el alcance](docs/REQUISITOS.md) y [el plan SQA](docs/sqa/TEST_PLAN.md).
2. Cada integrante usa su cuenta de GitHub, acepta la invitación a [MovilSQA](https://github.com/G34A4OD/MovilSQA) y trabaja con su guía:
   - [Gerardo](equipo/GERARDO.md): identidad, grupos, parentescos, seguridad transversal e integración.
   - [Eva](equipo/EVA.md): carpetas, documentos, archivos privados, automatización y reporte.
   - [Waldir](equipo/WALDIR.md): presupuesto, categorías, movimientos, CSV y métricas.
3. Sigue [el flujo GitHub y Planner](docs/COLABORACION.md). La rama compartida de integración será `develop`; `main` se reserva para releases revisados.

## Ejecutar la base móvil

Se conserva el proyecto existente en `app/`. Versión validada: Flutter 3.41.9 / Dart 3.11.5.

```powershell
cd app
flutter pub get
flutter run
```

La pantalla inicial indica **Demostración local**. Usa exclusivamente datos ficticios en memoria; al reiniciar se descartan los cambios. No es un login, un servidor ni un almacén seguro de documentos. El adaptador HTTP y los módulos productivos son trabajo de las historias del backlog.

```powershell
# Desde la raíz; genera evidencia con fecha, entorno, casos y métricas.
./scripts/verify.ps1
```

## Organización

| Ruta | Contenido |
|---|---|
| `app/lib/core/` | Dinero, validaciones y tema compartidos |
| `app/lib/features/` | Módulos por funcionalidad, con dominio/presentación |
| `web/` | Contrato y guía de implementación de API Laravel; no hay servidor implementado aún |
| `docs/api/` | Contrato HTTP, nombres y permisos congelados para trabajar en paralelo |
| `docs/sqa/` | Test Plan, casos, trazabilidad, auditoría y herramientas |
| `planificacion/` | Backlog, EDT, estimaciones y cálculo reproducible PERT/CPM |
| `.github/` | CI, plantillas de issue y PR |
| `evidencias/` | Índice de entrega y resultados reales |

Los PDF del curso permanecen en la carpeta local y se excluyen del repositorio. Sus páginas de referencia se registran en [FUENTES.md](docs/FUENTES.md).

## Situación de GitHub

GitHub CLI autorizado; veinte issues, cuatro milestones, `develop` como default y `main`/`develop` protegidas. Invitaciones Write enviadas a Eva (`pizzatoev`) y Waldir (`riblawaldir`), pendientes de aceptación. Ver [estado remoto](docs/GITHUB_ESTADO.md) y [flujo de colaboración](docs/COLABORACION.md). La base se entrega por PR para revisión independiente; todavía no hay release final. No guardar tokens ni contraseñas en archivos o chats.
