# Trazabilidad de preparación y backlog

Los tests de dominio/widget son evidencia parcial: no equivalen a aceptación de la HU completa ni a autorización en Supabase. Los TC diseñados completos están en CASOS_PRUEBA.md.

| HU/paquete | EDT | Issue real | Driver / revisor | Casos ejecutados de base | Estado del producto |
|---|---|---|---|---|---|
| PREP-01 | 1.0 | [#1](https://github.com/G34A4OD/MovilSQA/issues/1) | Gerardo / Waldir | — | Base preparada, revisión pendiente |
| HU-01 | 3.1 | [#2](https://github.com/G34A4OD/MovilSQA/issues/2) | Gerardo / Waldir | — | Planificado; sin aceptación ejecutada |
| HU-02 | 3.1 | [#3](https://github.com/G34A4OD/MovilSQA/issues/3) | Gerardo / Waldir | — | Planificado; sin aceptación ejecutada |
| HU-03 | 3.2 | [#4](https://github.com/G34A4OD/MovilSQA/issues/4) | Gerardo / Waldir | TC-FAM-01, TC-SEC-01 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-04 | 3.2 | [#5](https://github.com/G34A4OD/MovilSQA/issues/5) | Gerardo / Waldir | TC-FAM-02 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-05 | 3.2 | [#6](https://github.com/G34A4OD/MovilSQA/issues/6) | Gerardo / Waldir | TC-FAM-03, TC-FAM-04 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-06 | 3.3 | [#7](https://github.com/G34A4OD/MovilSQA/issues/7) | Gerardo / Waldir | TC-FAM-05 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-07 | 3.3 | [#8](https://github.com/G34A4OD/MovilSQA/issues/8) | Gerardo / Waldir | — | Planificado; sin aceptación ejecutada |
| HU-08 | 3.4 | [#9](https://github.com/G34A4OD/MovilSQA/issues/9) | Eva / Gerardo | TC-DOC-01 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-09 | 3.4 | [#10](https://github.com/G34A4OD/MovilSQA/issues/10) | Eva / Gerardo | TC-DOC-02 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-10 | 3.4 | [#11](https://github.com/G34A4OD/MovilSQA/issues/11) | Eva / Gerardo | — | Planificado; sin aceptación ejecutada |
| HU-11 | 3.5 | [#12](https://github.com/G34A4OD/MovilSQA/issues/12) | Waldir / Eva | — | Planificado; sin aceptación ejecutada |
| HU-12 | 3.5 | [#13](https://github.com/G34A4OD/MovilSQA/issues/13) | Waldir / Eva | TC-BUD-03 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-13 | 3.5 | [#14](https://github.com/G34A4OD/MovilSQA/issues/14) | Waldir / Eva | TC-BUD-01, TC-BUD-02, TC-UI-01 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-14 | 3.5 | [#15](https://github.com/G34A4OD/MovilSQA/issues/15) | Waldir / Eva | TC-BUD-02, TC-UI-01 | Dominio/widget parcial; Supabase y aceptación pendientes |
| HU-15 | 3.5 | [#16](https://github.com/G34A4OD/MovilSQA/issues/16) | Waldir / Eva | TC-BUD-04 | Dominio/widget parcial; Supabase y aceptación pendientes |
| QA-01 | 4.1 | [#17](https://github.com/G34A4OD/MovilSQA/issues/17) | Eva / Gerardo | — | Planificado; sin aceptación ejecutada |
| QA-02 | 4.2 | [#18](https://github.com/G34A4OD/MovilSQA/issues/18) | Eva / Gerardo | — | Planificado; sin aceptación ejecutada |
| QA-03 | 4.3 | [#19](https://github.com/G34A4OD/MovilSQA/issues/19) | Waldir / Eva | — | Planificado; sin aceptación ejecutada |
| OPS-01 | 5.1 | [#20](https://github.com/G34A4OD/MovilSQA/issues/20) | Gerardo / Waldir | — | Planificado; sin aceptación ejecutada |

Trazar después cada PR, commit, TC manual/automatizado y evidencia en el issue/Planner. El mismo TC puede cubrir varias condiciones; no contar HU completas como aceptadas por este mapa.

Arquitectura vigente: Flutter + Supabase directo. Cada HU necesita evidencia de las políticas RLS/grants/RPC y Storage que le correspondan además de sus tests Dart. La etapa actual de CI no ejecuta todavía esas pruebas Supabase. Las referencias a API en artefactos históricos no acreditan una API propia ni controles implementados.
