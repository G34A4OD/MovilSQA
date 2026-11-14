# Selección de automatización · Clase XIX

Evaluación preparada el 14/11/2026. Criterios: compatibilidad con producto, integración CI, curva de aprendizaje, costo/licencia, mantenimiento, reporte y comunidad. No se comparan precios numéricos: revisar condiciones antes de contratar. No se ha comprado ninguna licencia.

## Móvil: tres opciones abiertas y una comercial

| Herramienta | Licencia / entorno | Ventajas para Nido | Límites / costo de adopción | Decisión |
|---|---|---|---|---|
| Flutter integration_test + flutter_test | Código abierto, Dart, Flutter Android/iOS | Mismo lenguaje y acceso estable a widgets; unit/widget y E2E con herramientas oficiales | Dispositivo para E2E; iOS requiere macOS/Xcode; agregar captura/reporte | Elegida como base |
| Appium | Código abierto, drivers Android/iOS | E2E fuera de la app, múltiples lenguajes y dispositivos | Validar driver/semántica Flutter en piloto; más infraestructura, no asumir soporte de cada widget | Alternativa si docente exige o piloto justifica |
| Espresso | Código abierto, Android nativo | Integración Android y pruebas de vistas/puentes nativos | No iOS; Flutter no expone todos sus widgets como vistas Android tradicionales | Solo para integración nativa específica |
| Katalon Studio Enterprise / ejecución comercial | Producto comercial con capacidades web/API/móvil | IDE y reportes integrados, servicios de ejecución | Licencia/ejecución CI según edición; Flutter requiere compatibilidad/keywords y versiones concretas; validar piloto | Comparada, no adquirida ni seleccionada |

Fuentes primarias: [Flutter integration_test](https://docs.flutter.dev/testing/integration-tests), [Appium](https://appium.io/docs/en/latest/), [Espresso](https://developer.android.com/training/testing/espresso), [entornos Katalon](https://docs.katalon.com/katalon-studio/docs/supported-environments.html), [Flutter en Katalon](https://docs.katalon.com/katalon-studio/keywords/custom-keywords/flutter-based-application-testing-with-custom-settext-keyword-in-katalon-studio).

La valoración es una inferencia del contexto del equipo, no un benchmark. Elegimos herramientas oficiales Flutter por compatibilidad/lenguaje y mantenimiento; no afirmamos que ya se haya ejecutado integration_test en dispositivo. Las pruebas actuales son unidad/widget. Appium y Katalon requieren piloto de un formulario y una descarga antes de decidir.

## Web: tres opciones abiertas y una comercial

| Herramienta | Licencia / entorno | Ventajas | Límites | Decisión |
|---|---|---|---|---|
| Playwright Test | Código abierto, navegador/TS y otros bindings | Trace, screenshots, aislamiento y reporter; buena CI | No valida una APK nativa; probar Flutter web no sustituye Android | Elegida si se añade panel web Laravel |
| Selenium WebDriver | Código abierto, navegadores/múltiples lenguajes | Ecosistema amplio y Grid | Configuración de sincronización/reporte; no app nativa | Alternativa web |
| Cypress App | Runner de código abierto, JS/TS web; servicios Cloud separados | Experiencia de depuración e integración frontend | Restricciones del navegador y posibles servicios comerciales; no APK | Alternativa web |
| Katalon Studio Enterprise | Comercial, web/API/móvil | IDE y reportes en un producto | Licencia y ejecución según edición, integración/piloto por validar | Comparada, no adquirida |

Fuentes: [Playwright](https://playwright.dev/docs/intro), [Selenium](https://www.selenium.dev/documentation/), [Cypress](https://docs.cypress.io/app/get-started/why-cypress), [tecnologías Katalon](https://docs.katalon.com/katalon-studio/supported-technologies-for-katalon-studio).

El producto solicitado es móvil. La comparación web responde a la actividad de Clase XIX; no crea un portal web adicional obligatorio. PHPUnit HTTP sobre Laravel/PostgreSQL prueba la API sin depender de UI web. Newman puede ejecutar colecciones API exportadas si se elige Postman para diseño; no es necesario duplicar cada test PHPUnit.

## Integración y piloto

~~~mermaid
flowchart LR
  I[Issue + HU + TC + riesgo] --> R[Test que falla por causa esperada]
  R --> C[Implementación y refactor]
  C --> P[PR y revisión de compañero]
  P --> CI[CI: formato / análisis / unidad-widget / API]
  CI --> A[Artifacts JSON-JUnit-lcov y reporte]
  A --> M[Staging + E2E Android/iOS]
  M --> Q[Auditoría / métricas / correctivas]
  Q --> D[Aceptación + release]
~~~

Piloto actual: tests unidad/widget del presupuesto y dominio en scripts/verify.ps1. Eva debe ampliar a login -> grupo -> documento privado -> presupuesto -> CSV con servidor real, medir duración/mantenibilidad y adjuntar capturas. Explorar UX/accesibilidad manualmente; no automatizar juicio subjetivo como si fuera un resultado binario.

## Entregables de la actividad que faltan

Eva exporta esta matriz a Word o Excel, revisa fuentes/condiciones actuales y prepara presentación breve:

1. Contexto y riesgos de Nido.
2. Criterios de selección y matrices web/móvil.
3. Elección Flutter/PHPUnit y alternativas.
4. Piloto real, comandos, datos y resultado con limitaciones.
5. Flujo CI/reportes/Planner, costos de mantenimiento y siguiente mejora.

No presentar este texto como una presentación ya expuesta ni como firma de los tres integrantes.
