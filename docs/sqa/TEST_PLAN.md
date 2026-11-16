# Test Plan ágil · Nido · TP-02 v0.3

Preparado: 14/11/2026. Estado: listo para revisión del equipo/docente; no aprobado aún. Responsables de elaboración: equipo Gerardo, Eva y Waldir. Base: Plan SQA móvil pp. 1-4. Se usa Scrum con sprints de una semana, tablero Kanban y prácticas XP de pruebas y revisión cruzada.

## 1. Introducción

Propósito: prevenir filtraciones de información familiar y errores financieros mediante pruebas continuas, trazabilidad y revisión independiente. QA pertenece a todo el equipo. Se separa aseguramiento (proceso, inspecciones, auditorías y políticas) de control (ejecución y evaluación del producto). Los resultados de cada sprint actualizan este plan.

No se encontró un Test Plan previo del proyecto en la carpeta; no se inventa uno histórico. TP-01 es la línea base tradicional retrospectiva documentada en `REVISION_PLAN.md`; TP-02 incorpora el ciclo ágil y se mantiene bajo Git. Cambios del alcance pasan por issue, análisis de riesgo, revisión y versión del plan.

## 2. Alcance

Producto objetivo: RF-01..15 y RNF-01..08 de `docs/REQUISITOS.md`. Incremento de preparación: dominio puro de dinero, categorías/movimientos, grupos/invitaciones/admin, ascendencia y validación temprana de archivos; UI de demostración. La arquitectura elegida es Flutter + Supabase directo: Auth, PostgreSQL con RLS, RPC transaccionales y Storage privado, mediante supabase_flutter. Autenticación real, conexión, migraciones, políticas/RPC, archivos y E2E siguen pendientes; no están cubiertos por las pruebas de la demo. No se construye un producto web ni una API propia intermedia.

| Sprint propuesto | Alcance comprobable | Riesgo y entregable |
|---|---|---|
| S1 | Arquitectura/Supabase, RF-01/02, grupo mínimo y controles base | Identidad/pertenencia; login real y pruebas negativas |
| S2 | RF-03..10, carpetas y documentos seguros; categorías/hojas | Último admin, árbol y bytes privados; Flutter/Supabase integrados |
| S3 | RF-11..15 e integración completa | Cálculos, aislamiento, concurrencia, CSV y regreso sin red |
| S4 | Regresión, accesibilidad, rendimiento, restauración y entrega | Reportes, auditoría de cierre, release reproducible |

El backlog debe dividir historias mayores a una semana. Los sprints son propuesta relativa a la fecha de inicio que confirme el equipo. No se programa antes de cumplir DoR y obtener validación docente de casos de uso.

## 3. Estrategia de pruebas

Prioridad P0: acceso cruzado, sesión, último admin, archivos y dinero. P1: invitación, genealogía, exportación, CRUD. P2: presentación y usabilidad. Equivalencias/límites para montos (0, 0.01, máximo, máximo+0.01), mes (0/1/12/13), año (0/1/9999/10000), archivos (0/1/límite/límite+1 y firma). Tablas de decisión admin/miembro/ajeno, dueño/no dueño y grupo activo. Transiciones pendiente/aceptada/rechazada/expirada y miembro/admin/expulsado.

| Nivel / tipo | Herramienta y contexto | Cuándo / evidencia |
|---|---|---|
| Unidad (caja blanca y negra) | flutter_test para Dart; pruebas SQL/pgTAP para funciones de base de datos cuando existan | Cada cambio; JSON/JUnit/lcov o salida SQL con aserciones TC/HU |
| Widget | flutter_test, múltiples anchos y texto ampliado | Cada PR; navegación, validaciones y estados de error |
| Integración Supabase/DB | Supabase CLI y pgTAP en entorno local de pruebas; llamadas SDK con JWT de usuarios ficticios a Auth, Data API, RPC y Storage | Cada PR de migraciones/políticas; RLS, grants, FK, rollback, concurrencia e idempotencia. Suite pendiente de implementación |
| Aceptación móvil | integration_test en Android, iOS cuando haya macOS | Cada incremento integrado; flujo real Flutter -> Auth/Data API/RPC -> PostgreSQL/Storage |
| Alternativa móvil | Appium UiAutomator2/XCUITest, piloto antes de adopción | Si el docente exige o se valida compatibilidad con el árbol semántico Flutter |
| Regresión / smoke | Unidad + widget en CI, smoke de login/grupo/archivo/presupuesto en dispositivo | Cada PR y antes de tag |
| Seguridad | Casos BOLA/IDOR, masa asignable, tokens, MIME, revocación, CSV | P0 de cada historia; datos sintéticos y logs redactados |
| Exploratoria / accesibilidad | Sesiones humanas de 30 min con charter, TalkBack/VoiceOver, 200% texto | Cada sprint, capturas y hallazgos; no sustituida por screenshots automáticos |
| Rendimiento / recuperación | Carga reproducible de operaciones Supabase con 20 usuarios, dataset sintético; backup/restauración | S3-S4; p95, errores, tamaño, RPO/RTO reales |

Selección justificada en `HERRAMIENTAS.md`. Las herramientas de las diapositivas son ejemplos; se prioriza soporte oficial de Flutter. No se usa Playwright como sustituto de probar una APK.

BDD/ATDD: convertir criterios Dado/Cuando/Entonces de `ACEPTACION.feature` en tests y revisarlos con PO antes de codificar. TDD: conservar evidencia de prueba que falla por causa esperada, implementación verde y refactor verde. Un archivo `.feature` es especificación; no se declara ejecutado sin runner o test equivalente trazado.

## 4. Roles y responsabilidades

| Persona | Construye | Función SQA principal | Revisa / valida |
|---|---|---|---|
| Gerardo | Identidad, grupos, parentescos, mascotas e integración | PO propuesto + responsable arquitectura/seguridad; revisa criterios con docente | PR de Eva; aprobación funcional con equipo |
| Eva | Documentos y archivos privados | QA Champion y automatización/reportes | PR de Waldir; auditoría de permisos y evidencias |
| Waldir | Presupuesto, categorías, CSV | Scrum Master y métricas/planificación | PR de Gerardo; control de calidad financiera |

Los tres desarrollan, escriben pruebas, corrigen sus defectos y aportan evidencias. Nadie audita o aprueba su propio trabajo como revisión independiente. Auditoría cruzada: Eva modera, Waldir registra y Gerardo explica; cuando se inspeccione un módulo de Eva, Gerardo modera. Firmas son pendientes hasta revisión real.

## 5. Ciclo de vida de pruebas dentro del sprint

Lunes: revisar riesgos/cambios, seleccionar historias Ready, estimar y diseñar aceptación. Cada día: TDD, inspección y automatización; actualizar issue y GitHub Projects. Antes del PR: unidad/widget y las pruebas SQL/RLS/Supabase que correspondan, reporte y evidencia. Revisión: compañero ejecuta smoke y negativos, CI sobre commit exacto. Viernes: aceptación de PO/equipo, regresión, auditoría breve, métricas, retrospectiva con acción/dueño/fecha y release si pasa gates.

STLC por historia: analizar requisito -> planificar -> diseñar TC/datos -> preparar entorno -> ejecutar -> reportar defectos -> reejecutar/regresión -> cerrar. No esperar al último sprint para probar. Bug con pasos/esperado/actual/severidad/entorno/evidencia; clasificar bug de código, test inestable o infraestructura. Nunca reintentar silenciosamente hasta conseguir verde.

## 6. Criterios de entrada y salida

**Definition of Ready:** CU revisado/aprobado por docente, HU INVEST con criterios y riesgos, mockup Material 3, contrato y autorización definidos, TC trazados, EDT/PERT/CPM y tarea GitHub Projects con responsables, dependencias satisfechas, datos ficticios y entorno disponibles. Si falta aprobación docente, diseño puede prepararse y la historia se marca pendiente de Ready; no se presume aprobada.

**Definition of Done:** criterios pasan; tests P0 y regresión verdes; análisis sin errores; cobertura medida de dominio >=80% como objetivo (no presumida); revisión de otro integrante y conversaciones resueltas; seguridad multiusuario/multigrupo, sesión vigente y denegación de URLs firmadas verificadas con RLS, grants, RPC y políticas Storage/Edge de Supabase; documento/captura/log y metadatos ligados a commit/issue/PR; sin defectos críticos/altos abiertos; evidencia y GitHub Projects actualizados; aceptación humana registrada.

Entrada a release: historias Done, entorno staging disponible, backup y rollback definidos. Salida: tests ejecutados sobre commit/tag, APK probada y checksum, reporte de auditoría sin bloqueantes, defectos conocidos documentados, aprobación de equipo. Suspender ante filtración, corrupción, pérdida del último admin o entorno incorrecto; reanudar tras corrección y regresión P0.

## 7. Métricas y control de calidad

| Indicador | Fórmula / fuente | Objetivo / interpretación |
|---|---|---|
| Tasa de éxito | pasados / (pasados + fallidos) * 100; saltados por separado | P0 100%, total >=95% como objetivo; 0 ejecutados = N/D |
| Cobertura de líneas | hits>0 / líneas instrumentadas *100; lcov | Dominio >=80%; no equivale a cobertura de requisitos ni seguridad |
| Cobertura de requisitos | HU aceptadas con TC ejecutados / HU del sprint *100 | 100% para las historias declaradas Done |
| Densidad de defectos | bugs confirmados / KLOC no generadas o por HU (indicar denominador) | Comparar tendencia; sin denominador = N/D |
| Defectos por severidad | recuento de issues bug críticos/altos/medios/bajos | 0 críticos/altos para release |
| Velocidad | puntos de HU aceptadas por sprint | Solo puntos reales; no commits ni horas |
| Flakiness | tests con resultado alternante sin cambio / tests repetidos | Requiere varias ejecuciones; una sola = N/D |
| Duración | inicio-fin real, suite/entorno | Vigilar regresiones; comparar mismo entorno |
| Concurrencia / performance | p95 y error rate con carga definida | p95 <800 ms, <1% errores en staging (objetivos) |

El generador de reportes conserva total, passed/failed/skipped, fallos y trazabilidad de los tests Flutter. Las métricas de negocio/velocidad/defectos no se infieren de una suite verde; Waldir actualiza `METRICAS.md` con fuente y denominador. Inspección por PR, auditoría por sprint y reauditoría de acciones correctivas. Se conserva reporte fallido, no se reemplaza por captura verde sin explicación.

## 8. Riesgos y mitigación

| Riesgo | Prob. / impacto | Tratamiento y responsable |
|---|---|---|
| Exposición de salud/identidad | Media / crítica | RLS y grants mínimos, privado, minimización y pruebas negativas; Gerardo/Eva |
| Carrera de último admin/aceptación | Media / alta | Lock transaccional en PostgreSQL y prueba concurrente; Gerardo |
| Errores decimales/mezcla de años | Alta / alta | Centavos, límites, aislamiento y oráculo independiente; Waldir |
| CSV malicioso | Media / alta | Escape y neutralización, abrir con planilla en entorno aislado; Waldir |
| Conflictos entre agentes | Alta / media | Módulos exclusivos, contrato previo, PR pequeños; Gerardo |
| Sin Android/iOS disponible | Media / alta | Emulador temprano, iOS pendiente explícito sin macOS; Eva |
| Alcance mayor que calendario | Alta / alta | Vertical slices, priorizar P0, reestimar con equipo sin omitir requisitos silenciosamente; Waldir |
| Falta permisos GitHub/GitHub Projects | Media / media | Preparación local, autenticar/invitar, registrar bloqueo real; Gerardo |
| Evidencia sin metadatos o ficticia | Media / alta | Script reproducible, commit/hu/tc, firmas reales; Eva |

## Evidencias y trazabilidad de la rúbrica

| Criterio | Peso | Evidencias de entrega |
|---|---:|---|
| Actualización coherente del Test Plan | 25% | Este plan + REVISION_PLAN + historial de versiones |
| Estrategias de pruebas | 20% | Código tests, red/green/refactor, BDD/ATDD, pipeline y resultados reales |
| Control y seguimiento | 20% | Auditoría, inspecciones, defectos, acciones verificadas y métricas |
| Documento y presentación | 15% | Revisión editorial, matriz Word/Excel y presentación breve de herramientas/demo |
| Participación colaborativa | 20% | Tres cuentas, issues/GitHub Projects, commits, PR y revisiones cruzadas con evidencia |

La clase XIX solicita comparar tres herramientas abiertas y una comercial **para web y móvil**; la matriz y su exportación final a Word/Excel y presentación pertenecen a Eva con revisión de Gerardo. La clase XX exige metadatos, fallos, capturas UI, trazabilidad y firmas: usar el reporte generado y completar las validaciones humanas. Índice final en `evidencias/INDICE.md`.

## Alcance actual de CI y pruebas Supabase pendientes

El pipeline implementado ejecuta formato, análisis, tests Flutter de unidad/widget y tests Python del generador de reportes. Aún no ejecuta Supabase CLI/pgTAP, RLS, RPC, Edge Functions, Auth/Storage ni E2E en dispositivo. La cobertura Dart de la base no mide esas capas. Al implementar migraciones/políticas, Gerardo integra una etapa separada y trazable de pruebas Supabase con datos sintéticos; conservar su salida y metadatos sin convertir pruebas diseñadas en ejecutadas.

Usar los nombres y permisos de docs/api/CONTRATO.md. Los negativos deben ejecutarse con usuarios/roles no privilegiados y JWT reales de pruebas además de los tests SQL; usar service_role o el propietario de la BD podría eludir RLS y producir falsa confianza. Comprobar perfiles privados separados de datos públicos, grants de columnas sensibles y prohibición de escribir directamente is_admin/membresías fuera de RPC autorizadas. Para concurrencia, dos conexiones independientes deben intentar las salidas/degradaciones y verificarse el estado final.

Logout elimina sesión local e invalida la renovación conforme al alcance de signOut; la firma de un JWT de acceso ya emitido puede seguir válida hasta expirar. Para los datos sensibles de Nido es obligatorio implementar y probar el helper privado de sesión vigente definido en SEGURIDAD.md (por ejemplo has_live_session): contrasta el session_id del JWT con su sesión Auth, sin exponer auth.sessions al cliente, y se aplica en policies, RPC y lecturas de Storage/Edge sensibles. No es un control opcional de la entrega. Reutilizar un JWT todavía vigente después de finalizar esa sesión en Auth debe impedir filas/bytes y mutaciones sensibles; una sesión vigente autorizada debe permitirlos. Otra sesión activa del mismo usuario no debe reactivar el JWT de la sesión terminada. Esta es una garantía del guard aplicado, no de la firma JWT ni de signOut por sí solos; la demo aún no la implementa ni acredita.

La pertenencia también se consulta en BD en cada operación: una nueva petición después de salida/expulsión no accede al grupo aunque la sesión Auth permanezca activa. RLS puede filtrar SELECT o mutaciones y devolver cero filas; evaluar filas/bytes ausentes y verificar el estado final intacto, o la denegación documentada, sin exigir siempre 401/403. Los casos permitidos equivalentes deben demostrar una lectura o escritura real para evitar un falso verde por cero filas en ambos casos. Una copia descargada o transferencia ya iniciada no es revocable.

P0 de Storage: intentar createSignedUrl desde un cliente normal modificado incluso mientras sigue siendo miembro y repetir tras salir/ser expulsado; no debe obtener una URL de lectura reutilizable que sobreviva a la revocación. Según el contrato, separar operaciones Storage en la policy (solo lectura autenticada y sus comprobaciones), sin otra policy permisiva que permita firma/listado. Verificar los helpers por operación en la versión desplegada. Si esa separación no está disponible, denegar SELECT Storage directo al móvil y probar el fallback Edge autenticado que verifica sesión/documento/membresía y devuelve bytes, sin emitir enlaces firmados. Ocultar el método en Flutter no cumple el control.

Referencias técnicas: [pruebas Supabase](https://supabase.com/docs/guides/local-development/testing/overview), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [sesiones Auth](https://supabase.com/docs/guides/auth/sessions) y [acceso a Storage](https://supabase.com/docs/guides/storage/security/access-control).
