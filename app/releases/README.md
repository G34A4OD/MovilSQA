# APK de las iteraciones

Las diapositivas XP pp. 57-58 exigen APK **release** versionada y probada por otro integrante, además de URL pública de API, CI verde, PR aprobados y tag/release.

Esta preparación todavía no incluye APK ni firma productiva. La configuración inicial Android usa firma debug incluso en build release; Gerardo debe configurar keystore de pruebas/release seguro antes de la entrega. No subir el keystore ni `key.properties`.

Después de aceptación del sprint: `flutter build apk --release`, copiar el APK validado a `app/releases/app-v0.N.0-release.apk` (se conserva `app/` en lugar del nombre `movil/` de ejemplo), generar SHA-256 y registrar instalación/pruebas en teléfono. GitHub limita cada archivo Git a 100 MB; revisar tamaño. Adjuntar también a GitHub Release. No etiquetar esta base como v1.0.0.

La instalación en el dispositivo la realiza cada integrante conforme a sus permisos y configuración. Guardar evidencia de versión/build y pruebas, sin datos reales.
