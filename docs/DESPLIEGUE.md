# Despliegue móvil y configuración Supabase por sprint

Producto único: app Flutter. Infraestructura: Supabase Auth, PostgreSQL/RLS, Storage privado y funciones SQL/RPC; Edge Functions solo para operaciones confiables del contrato. No hay sitio web ni hosting de servidor propio que desplegar. La aclaración del usuario sustituye el stack del proyecto anterior.

Estado: guía preparada; proyecto Supabase sin conectar, migraciones/RLS/RPC y funciones pendientes. La demo actual continúa en memoria.

1. Gerardo inicializa Supabase local/staging y publica esquema/permisos base. Eva/Waldir incorporan sus módulos con migraciones propias y revisión cruzada.
2. Elegir proyecto Supabase de pruebas con datos ficticios; separar staging/producción. Fijar CLI/SDK y configurar URL + clave publishable para Flutter. Secretos de CLI/DB/Edge Functions solo en configuración protegida. Ver SUPABASE.md.
3. Probar migraciones desde cero con fixtures, pgTAP/SQL para RLS/RPC y clientes con JWT de prueba para Auth/Storage. No usar clave privilegiada como cliente de aceptación. Agregar un job de infraestructura cuando exista entorno: hoy CI valida Flutter y el reportador.
4. Tras CI y revisión, publicar solo migraciones/funciones aprobadas a staging. No ejecutar db reset sobre un proyecto remoto con datos. Migraciones y app deben ser compatibles durante el despliegue.
5. E2E de login, grupos, archivos, presupuesto y CSV en Android contra Supabase staging. iOS con macOS/Xcode; registrar pendiente si falta. Un build web no demuestra Android/iOS.
6. PR develop -> main aprobado, checks verdes y pruebas sobre la versión concreta; tag v0.N.0. Generar APK release firmado y SHA-256. La futura conexión podrá leer configuración dart-define; la demo actual aún no lo hace.
7. Copiar APK a app/releases y GitHub Release según el flujo acordado; adjuntar demo, resultados, defectos conocidos y enlaces GitHub Projects. Registrar versión del esquema y del binario.

Rollback: conservar binario anterior y backup probado de DB y objetos Storage. Revertir código por PR; corregir migraciones aplicadas con nuevas migraciones compatibles, sin borrar historial o resetear base remota. Operaciones destructivas requieren restauración ensayada. Confirmar respaldos del plan elegido sin asumir que DB incluye Storage.

Supabase entrega las URLs de servicio para la app; no se añade una web pública como requisito. Publicación en tiendas y recursos pagados requieren decisiones propias; no están realizados por preparar un APK.
