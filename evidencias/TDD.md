# TDD y validación de la preparación

Secuencia realmente ejecutada el 14/11/2026:

1. Se escribieron primero los tests de dominio. `flutter test --machine test/domain` terminó con exit 1 porque los tipos/archivos aún no existían. Es rojo de compilación, no un fallo funcional de servidor. Log: `tdd/red.jsonl`.
2. Se implementaron reglas de dinero, presupuesto, grupos y validación temprana de documentos. La ejecución conjunta inicial pasó dominio y falló en dos widget tests: el botón estaba fuera del árbol construido por el ListView. Se corrigió el test para desplazar hasta el control y se corrigieron avisos de estilo. Log: `tdd/green-inicial-con-fallo-ui.jsonl`.
3. Se mejoró el ciclo de vida de los controladores de diálogo para liberarlos al completar la ruta y se repitieron los tests de interfaz: dos pasaron.
4. La ejecución final `base-final-01` pasó formato, análisis y 19 tests, con JSON/JUnit/lcov y metadatos. Resultado revisable en `base/report.md`. Los cinco tests del generador de reportes también pasaron; usan fixtures sintéticos en temporal y **no** se cuentan como pruebas funcionales de la app.

Estas evidencias son logs reales locales, anteriores al primer commit de la base; no se fabrica un historial rojo/verde con commits retroactivos. Las historias siguientes deben conservar sus commits y tests conductuales de cada ciclo. No hay evidencia todavía de servidor, dispositivo, seguridad productiva o revisión de otro integrante.
