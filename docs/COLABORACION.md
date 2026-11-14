# GitHub, XP y Planner para tres personas

Repositorio: https://github.com/G34A4OD/MovilSQA. Cada integrante usa su cuenta real. Eva y Waldir deben recibir y aceptar invitación de colaborador; un repositorio público permite clonar pero no da permiso de push. Gerardo necesita sus nombres de usuario para invitarlos. No compartir cuentas ni fabricar coautorías.

## Preparación del propietario

1. Ejecutar `gh auth login --web --git-protocol https` y comprobar `gh auth status` sin copiar tokens.
2. Publicar la rama de preparación mediante PR. Crear `develop` desde la base remota existente y establecerla como default; mantener `main` como rama de releases.
3. Crear labels, milestones e issues con `scripts/bootstrap-github.ps1`. Primero revisar su salida en modo lectura; después ejecutar `-Apply`. El script no hace merge, no emite aprobaciones y no modifica permisos.
4. Proteger `main` y `develop`: PR obligatorio, una aprobación de otro integrante, descartar aprobación con nuevos commits, conversaciones resueltas, check `flutter-quality` obligatorio; bloquear force push y borrado. El check debe existir tras la primera ejecución antes de seleccionarlo. Incluir administradores cuando el plan del repo lo permita. Si GitHub rechaza protección por plan/licencia, registrar limitación y revisión manual, sin decir que está activa.
5. Activar Issues/Actions. Configurar permisos mínimos y confirmar visibilidad del repositorio antes de subir material del curso o evidencias; solo datos ficticios.

## Trabajo diario

```powershell
git status
git fetch origin
git switch develop
git pull --ff-only origin develop
# Sustituir 12 por el número REAL asignado al issue de la historia.
git switch -c feature/12-documentos-carpetas
# Implementar y probar; agregar únicamente rutas propias revisadas.
git add app/lib/features/documents app/test/documents
git diff --cached
git commit -m "feat(movil): agrega carpetas #12"
git push -u origin feature/12-documentos-carpetas
# Escribir el cuerpo en un archivo temporal con nuevas líneas reales.
gh pr create --base develop --title "[3.4] Agrega carpetas" --body-file tmp/pr-body.md
```

Cuerpo PR: problema, HU/CU/EDT, comportamiento final, pruebas y entorno, enlace a evidencia, riesgo pendiente y `Closes #12`. Como `develop` será default, el cierre automático opera al integrar allí. Antes de ese cambio, un PR a rama no default no garantiza cerrar el issue automáticamente.

Commits `tipo(alcance): verbo #issue`, título máximo 50 caracteres cuando sea posible; cuerpo con detalle. Ramas `feature/`, `fix/`, `test/`, `docs/`, `refactor/`; una historia pequeña por rama, vida 1-3 días. No commit directo a main/develop ni force push a ramas compartidas.

## Revisión cruzada y XP

Rotación: Gerardo desarrolla y Waldir revisa; Eva desarrolla y Gerardo revisa; Waldir desarrolla y Eva revisa. Rotar driver/navigator cada 25-30 minutos si trabajan en pareja, registrar sesión y decisiones con participantes reales. Usar `Co-authored-by` solo si hubo participación verificable y con correo consentido.

El revisor ejecuta `gh pr checkout NUMERO`, instala dependencias, corre pruebas y valida los criterios desde el móvil/API. Comenta usuario, commit, entorno, pasos, esperado/actual y evidencia. Un agente puede preparar la revisión; la cuenta del autor no aprueba su propio PR. El merge lo realiza otro integrante después de la aprobación y CI verde.

## Conflictos y archivos compartidos

- Gerardo custodia core, punto de composición, dependencias, locks, contrato, CI y rutas agregadoras.
- Eva y Waldir agregan archivos en sus módulos; solicitan registro de rutas/dependencias en PR previo pequeño.
- Para actualizar la rama: `git fetch origin` y `git merge origin/develop`; resolver archivo por archivo, sin aceptar todo «ours/theirs». Ejecutar pruebas después. No regenerar locks a mano.
- No usar `reset --hard`, `clean -f` ni `push --force` como solución de conflictos. Si el árbol está sucio, primero guardar un commit propio o stash identificado.
- Revisar `git diff --check` y `git diff --cached` antes de cada commit; no agregar todos los PDF ni carpetas de caché.

## Planner como tablero del curso

Crear un plan del equipo Microsoft 365 con columnas Backlog, Iteración, En progreso, En revisión (PR), Hecho. Cada tarea `[EDT] #issue Título` enlaza issue, PR, HU, test y evidencia; se asigna a driver y revisor. Labels: fase EDT, Ruta crítica, Móvil, Seguridad cuando aplique. Fechas reales se completan desde CPM al confirmar inicio/disponibilidad; no inventar una fecha de entrega.

Al crear issue -> Backlog; al planificar -> Iteración; rama activa -> En progreso; PR -> En revisión; aprobación + CI + merge -> Hecho. Capturar vista del tablero por sprint y enlaces antes/después. GitHub Projects puede ser complemento; no declarar sincronización automática con Planner si no existe. El script no accede a Microsoft 365.

## Tags y releases

Al final de cada sprint aprobado: PR `develop -> main`, reejecutar pruebas sobre el commit integrado y crear tag anotado `v0.1.0`, `v0.2.0`, `v0.3.0`, entrega `v1.0.0`. `vX.Y.Z+N` del pubspec acompaña build. Nunca etiquetar esta base como aplicación final.

```powershell
git switch main
git pull --ff-only origin main
git tag -a v0.1.0 -m "Sprint 1 validado"
git push origin v0.1.0
gh release create v0.1.0 --verify-tag --generate-notes --draft
```

Revisar release draft con APK firmado de pruebas, checksum SHA-256, instrucciones, reporte, defectos conocidos y demo; después publicar con autorización del equipo. Firma de Android mediante secretos protegidos; no subir keystore. Evidencias de participación: commits propios + PR + revisión cruzada + pruebas + tarea Planner por cada persona, no solo conteo de líneas.
