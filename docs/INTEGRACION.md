# Integración y revisión de los incrementos

Estado al 14/11/2026. Fecha objetivo: martes 17/11/2026. Las solicitudes de revisión a Waldir son reales; no hay aprobación ni merge automático del autor.

## Orden de revisión

Los PR se apilaron porque #21 todavía no estaba integrado. Cada uno compara una historia con la anterior; no son nueve implementaciones independientes de la base.

| Orden | PR | Issue | Contenido |
|---|---|---|---|
| 1 | [#21](https://github.com/G34A4OD/MovilSQA/pull/21) | #1 | Preparación SQA y base móvil |
| 2 | [#23](https://github.com/G34A4OD/MovilSQA/pull/23) | #22 | G0, SDK y esquema/RLS compartidos |
| 3 | [#24](https://github.com/G34A4OD/MovilSQA/pull/24) | #2 | Auth y sesión segura |
| 4 | [#25](https://github.com/G34A4OD/MovilSQA/pull/25) | #3 | Perfil privado e ID público |
| 5 | [#26](https://github.com/G34A4OD/MovilSQA/pull/26) | #4 / #3 | Grupos y consentimiento por grupo |
| 6 | [#27](https://github.com/G34A4OD/MovilSQA/pull/27) | #5 | Invitaciones y búsqueda exacta |
| 7 | [#28](https://github.com/G34A4OD/MovilSQA/pull/28) | #6 | Administración y salida concurrentes |
| 8 | [#29](https://github.com/G34A4OD/MovilSQA/pull/29) | #7 | Parentescos y árbol |
| 9 | [#30](https://github.com/G34A4OD/MovilSQA/pull/30) | #8 | Mascotas |

El incremento OPS-01 (#20), rama codex/20-mobile-qa, depende de #30. Consultar el PR enlazado en la issue para obtener su número real.

1. Revisar, probar y aprobar #21 desde otra cuenta; fusionar a develop con **merge commit** para conservar la ascendencia de la pila.
2. Antes de fusionar el siguiente PR, cambiar su base a develop. Revisar el diff resultante, esperar CI y aprobación sobre su último commit. Fusionar a develop; repetir el orden de la tabla.
3. No fusionar un hijo en la antigua rama de funcionalidad. Si una revisión cambia la base, incorporar esos cambios en el hijo mediante merge normal y repetir pruebas. No usar force push para reorganizar la pila.
4. Squash/rebase de una base elimina su ascendencia compartida: requiere reconstruir y revisar las ramas dependientes. Para esta pila se recomienda merge commit.
5. Mantener las protecciones existentes. Cuando los workflows estén integrados en develop, evaluar exigir también sql-security y android-build; exigirlos antes bloquearía PR antiguos que todavía no los contienen.

## Inicio de Eva y Waldir

Ambas cuentas aceptaron acceso Write. Las issues ya tienen assignee y tareas en [Projects](https://github.com/users/G34A4OD/projects/1/views/1). Revisar contrato y guías actuales, actualizar el estado real y enlazar PR/evidencia en cada tarea. No marcar Done por tener código local.

La vía compartida es develop tras integrar la base. Mientras la revisión esté pendiente, pueden preparar su módulo en una rama propia desde codex/8-pets, declarando esa dependencia en su PR; no crear una segunda base de Auth/familias. Coordinar con Gerardo antes de editar main/core/dependencias/configuración/CI. Un PR apilado no equivale a revisión aprobada.

Crear migraciones con `npx.cmd --yes supabase@3.1.0 migration new NOMBRE_MODULO`, versión posterior a todas sus dependencias reales. Abandonar los lotes de ejemplo 0001xx..0004xx. No editar migraciones aplicadas. Tests pgTAP en supabase/tests/database, con prefijo único por módulo.

Eva debe comprobar owner_access_epoch, sesión y dueño/miembro vigente en filas y bytes; mascotas y familias eliminadas no se autorizan. Waldir debe comprobar dueño de hoja, miembro vigente y has_live_session. Ambos prueban llamadas directas con JWT normales, además de UI.

## Acceso a Supabase

Para ejecutar Flutter bastan URL, publishable key y cuentas ficticias propias; no necesitan la sesión de Gerardo ni claves elevadas. Para administrar dashboard/migraciones, una invitación individual de Supabase es independiente de GitHub; no se ha acreditado que esté concedida. Pueden trabajar con CLI/Docker local y enviar migraciones por PR para despliegue coordinado. No solicitar ni compartir contraseñas, service_role o tokens personales.

## Gates de entrega

Documentos/Storage y presupuesto aún necesitan sus incrementos. La cola cleanup_jobs retira acceso lógico pero todavía requiere worker de purga coordinado con los archivos de Eva. delete-account es diseño pendiente, no una función desplegada. No habilitar esas operaciones como si la limpieza estuviera terminada.

Antes de release: módulos integrados y revisados, negativos de bytes/CSV, prueba cruzada y accesibilidad, rendimiento medido, ensayo de rollback, backup de objetos, APK de entrega firmada, checksum y aceptación del equipo. La copia PostgreSQL local no acredita backup de Storage ni restauración del proveedor. Un tag final solo se crea después de cumplir esos gates.
