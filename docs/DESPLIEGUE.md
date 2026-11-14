# Despliegue y entrega por sprint

Diseño, todavía sin hosting/API desplegados. El PDF XP pp. 54-58 pide URL pública funcionando, CI/CD verde, tag/release, APK release y revisión cruzada. Supabase como PostgreSQL aparece en p. 56.

1. Gerardo inicializa Laravel, migraciones/factories y tests PostgreSQL. Eva/Waldir integran sus módulos mediante PR.
2. Elegir hosting Laravel (por ejemplo Render/Koyeb según disponibilidad/condiciones actuales) y Supabase de pruebas. Configurar secretos solo en servidor/GitHub Secrets; no contratar servicios o crear recursos de pago sin decisión del usuario.
3. Pipeline servidor: composer install desde lock, validar configuración, tests con PostgreSQL de CI, formato, auditoría de dependencias. No usar producción como DB de tests.
4. Staging en develop tras CI; despliegue con hook/CLI autenticado y HTTPS. Migraciones compatibles, backup previo, datos ficticios. Health check sin secretos y versión/build pública mínima.
5. E2E de login, grupos, documento privado, presupuesto y CSV en Android contra staging. iOS con macOS/Xcode cuando disponible; marcar pendiente si falta, nunca convertir web responsive en evidencia iOS.
6. PR develop -> main revisado por otro integrante y CI verde; tag anotado v0.N.0. Desplegar solo el commit/tag aceptado; generar APK firmado de release y SHA-256.
7. Copiar APK a app/releases según guía del curso y GitHub Release; notas, demo, reportes, riesgos conocidos y evidencia Planner.

Rollback: mantener release anterior y backup probado; revert mediante PR del commit de despliegue, sin force push. Migraciones destructivas requieren plan propio y restauración ensayada. Verificar si el backup PostgreSQL incluye objetos Storage (no asumirlo); respaldarlos separadamente.
