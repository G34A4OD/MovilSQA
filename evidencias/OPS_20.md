# OPS-01 · issue #20 · 14/11/2026

Incremento de Gerardo: prueba Android real de identidad/familia, restauración PostgreSQL local, configuración Auth, compilación Android CI y correcciones de revisión. Es preparación de entrega; #20 permanece en revisión hasta integrar los módulos y cumplir los gates. No se emitió tag ni release final.

## Resultados ejecutados

| Capa | Ejecución | Resultado y límite |
|---|---|---|
| Flutter unidad/widget/análisis/formato | ops-20-final | 45/45 PASS; sin incidencias de análisis; cobertura global 52,44%, dominio 88,81% (246/277 líneas) |
| Generador de reportes/plan de issues | unittest discover scripts/tests | 9/9 PASS |
| PostgreSQL/RLS/RPC | SQL final OPS | 150 aserciones PASS, siete archivos pgTAP; no son tests de bytes Storage |
| Auth HTTP local | auth-ops-final | 31 comprobaciones PASS con JWT de usuarios ficticios |
| Familia/Edge HTTP local | family-ops-final | 48 comprobaciones PASS; incluye guard SQL directo tras logout |
| Android físico | android-20-08; reejecución final android-20-09 | PASS en ambas; un escenario integration_test, 12 comprobaciones; metadatos de la reejecución final en ops/android-20-09.json |
| Copia/restauración | backup-20-02 | PASS en BD temporal local; owners/ACL preservados, RLS verificada como authenticated; no restaura bytes Storage ni nuevo clúster |

El escenario Android cubre registro con correo Mailpit y callback PKCE nativo, perfil, almacenamiento seguro, grupo, mascota, búsqueda Edge/invitación, aceptación con otra cuenta y ausencia de acciones admin, árbol, consentimiento, JWT capturado antes de logout sin filas privadas, recuperación PKCE y acceso con nueva contraseña. Usa Supabase LOCAL mediante adb reverse; no afirma entrega SMTP del proyecto remoto. Equipo TECNO KN4, Android 16/API 36; datos ficticios.

Los scripts anotan el commit padre 05973fd y dirty=true porque se ejecutaron antes del commit OPS. El hash de fuentes normalizadas liga el escenario a los archivos probados; CI volverá a validar el commit publicado. No renombrar ese commit como si hubiera sido probado en el teléfono. Los artifacts de GitHub identifican su propio SHA.

## Correcciones y fallos conservados

- Caché vacía de path_provider_windows 2.3.0: primera compilación fallida; se conservó la carpeta incompleta y se descargó únicamente ese paquete. La siguiente APK compiló y arrancó.
- ADB perdió conexión y hubo bloqueo de puerto; intentos android-20-02/03 registran BLOCKED_DEVICE. El usuario reconectó/autorizó el TECNO. No se cuentan como pruebas aprobadas.
- android-20-04/05: helper intentó pulsar parentesco fuera de pantalla. android-20-06: gesto de regreso fue consumido por InteractiveViewer. Se corrigieron sincronización y desplazamiento de la lista; #07 pasó el escenario completo. Son defectos del test, no evidencia TDD roja funcional del producto.
- #08 repitió el escenario con Secure password change activo y preservó tres PNG antes de que flutter test retirara el APK de integración. #09 ajusta el encuadre de mascota y prueba el código final con la etiqueta «No sé».
- backup-20-01 falló por permisos de pg_restore como postgres sobre objetos Auth. #02 restauró como supabase_admin exclusivamente local, preservando propietarios/permisos, y luego comprobó RLS como authenticated. No se borraron ni omitieron ACL para obtener verde.

Los intentos completos y dumps permanecen ignorados en evidencias/ejecuciones; se versionan solo metadatos/resúmenes revisados y capturas ficticias. No publicar claves locales de arranque, JWT, contraseñas temporales ni dumps.

## Observaciones reales de Waldir

Se atendieron los comentarios de PR #25 y #27 en este incremento, sin atribuirle ejecución de pruebas que no realizó:

- UI de sangre «No sé»; persiste null, sin admitir texto arbitrario en el check SQL.
- RPC directa: autoinvitación e invitación a miembro activo denegadas; sin nuevas filas ni alteración de miembros.
- Antes de logout, invitaciones visibles como control positivo. Después, el mismo JWT aún no expirado pasa Data API pero obtiene 200 con []; lookup_family_user directo devuelve 403/42501/forbidden. El resultado distingue guard SQL del rechazo de Auth en la Edge.
- El HTTP de un solo grupo dejó de llamarse «multigrupo». El multigrupo real se prueba en 003_groups.test.sql.

Waldir registra aprobaciones de #21/#23..27 con límites; #28..30 y este incremento necesitan su propia revisión. Las observaciones nuevas requieren revisar este diff. No hubo autoaprobación ni merge del autor.

## Configuración y reproducibilidad

Dashboard remoto nido-dev: Site URL/redirect exacto nido://auth/callback, confirmación de email, mínimo 12 y cambio seguro de contraseña. Capturas en ui/supabase-*.jpg. config.toml local alineado; no asumir que CLI local modifica Auth remoto.

La suite Android permite HTTP únicamente a 127.0.0.1:54321, con build debug y flag explícito SUPABASE_LOCAL_TEST. Release exige HTTPS; no hay excepciones de red globales. Android desactiva backup y activa FLAG_SECURE en build no depurable. La APK de CI usa configuración ficticia y demuestra compilación del producto conectado; no sirve para entrar a nido-dev.

Comandos en supabase/LOCAL.md. verify.ps1 genera JSON/JUnit/HTML/lcov. Restauración: scripts/test_backup_restore_local.py; Android: scripts/test_android_local.py. Los scripts administran solo fixtures locales y verifican permisos normales con JWT/rol de cliente.

## Pendiente para release

Documentos/Storage/cuarentena/escáner de Eva; presupuesto/CSV/métricas de Waldir; worker físico de cleanup_jobs, integración y regresión conjunta. delete-account sigue como contrato pendiente, no desplegado. No afirmar purga física por el borrado lógico.

Faltan aceptación docente/equipo, revisión cruzada completa, TalkBack/texto 200%/sin red/segundo plano, iOS, carga y p95, backup de objetos, ensayo de rollback, firma de entrega y release. La APK de desarrollo con checksum no es un release final. Seguir docs/INTEGRACION.md y mantener #20 abierta hasta completar los gates.

## APK de desarrollo instalada

Build normal lib/main.dart con configuración pública de nido-dev, instalado y arrancado en el TECNO (PID observado 22596). Copia local ignorada: entrega/nido-dev-debug.apk. SHA-256: `8b0ac37d74b858aea865786aea8425ff088f153d6f023f80c383d2d5827cce99`. El JSON ops/android-preview.json conserva tamaño/entorno/target. Es APK debug, no release final ni firmada para distribución de producción; reemplaza el target de integración que usaba datos ficticios locales.
