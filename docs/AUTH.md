# Cuenta móvil · HU-01 / issue #2

Implementación: Supabase Auth directo con SDK 2.18.3 fijado. Email/password, confirmación de correo, acceso, solicitud de recuperación, callback PKCE y contraseña nueva. El móvil nunca persiste contraseñas ni datos del perfil en Auth metadata. Sesión y verificador PKCE se guardan en flutter_secure_storage por proyecto; los logs SDK están desactivados.

Arranque conectado:

~~~powershell
cd app
flutter run --dart-define-from-file=config/supabase.local.json
~~~

El archivo local ignorado contiene únicamente SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY. Un error de configuración muestra un aviso; no abre automáticamente la demo. Para ejecutar la demostración en memoria, usar --dart-define=NIDO_DEMO=true. Los tests de la demo siguen usando NidoApp explícitamente.

En Supabase Dashboard de nido-dev, revisar Authentication / URL Configuration: permitir exactamente nido://auth/callback. En Email: habilitar confirmación; contraseña mínima 12 caracteres. La configuración local ya incluye ambos ajustes; no asumir que config.toml cambia automáticamente el proyecto remoto. Probar correo con usuarios ficticios; SMTP/entrega real y límites del plan necesitan validación del entorno.

Android: permiso Internet en release, auto backup deshabilitado y callback por intent-filter. iOS: URL scheme y FlutterDeepLinkingEnabled=false para que app_links/Supabase procesen el callback. PKCE limita la posibilidad de canjear un código interceptado; la validación en Android/iOS debe probar el enlace desde correo, proceso cerrado y abierto. No se afirma esa ejecución sin dispositivo.

Cerrar sesión usa SignOutScope.local: termina esta sesión del dispositivo, no todas las sesiones del usuario. Solo tras éxito se borra la pantalla de cuenta; ante fallo se solicita reintentar, sin fingir revocación. La firma JWT anterior puede seguir vigente, pero private.has_live_session() impide nuevas lecturas sensibles al desaparecer su session_id de Auth. No invalida copias ya descargadas.

Pruebas: scripts/test_auth_local.py apunta solo a localhost. Alta/login/logout/refresh/recuperación reales por HTTP; usa Admin únicamente como fixture para generar tokens ficticios de confirmación/recuperación y borrar la cuenta. Comprueba filas con JWT de usuario y clave pública, nunca con Admin. La generación de esos tokens no prueba el enlace recibido por correo ni la navegación móvil PKCE. Tests Flutter usan repositorio falso para validar estados/errores, no para acreditar RLS.
