# Estado de la entrega de preparación

Fecha de preparación: 14 de noviembre de 2026, America/La_Paz.

## Incluido

- Revisión del plan móvil y de las clases XIX, XX y Git/GitHub XP; catálogo del resto de clases.
- Alcance completo del producto, decisiones de arquitectura, privacidad y contrato de API.
- Plan SQA ágil con las ocho secciones y matriz de la rúbrica.
- EDT, PERT/CPM calculable, backlog y reparto de módulos verticales para tres integrantes.
- Tres guías con prompts listos para sus agentes y revisión cruzada.
- Base Flutter Material 3, dominio financiero y de grupos, demostración en memoria y pruebas.
- Pipeline de validación, generador de reportes y plantillas GitHub.
- Veinte issues, cuatro milestones, develop como default, ramas protegidas e invitaciones enviadas.
- Documentación alineada a Flutter + Supabase directo: Auth, RLS, Storage privado y RPC. Sin proyecto conectado ni migraciones/políticas implementadas aún.

## Aún por implementar y demostrar

Registro/login con Supabase Auth, persistencia con supabase_flutter/PostgreSQL, migraciones, políticas RLS/grants y RPC transaccionales, invitaciones entre cuentas, árbol completo, carga/lectura privada de PDF/fotos, edición del perfil, gestor financiero persistente, exportación/descarga en dispositivo, accesibilidad y pruebas E2E en Android/iOS.

El código local de dominio no sustituye los permisos RLS/Storage ni las transacciones PostgreSQL. La app móvil no necesita un sitio web ni una API propia intermedia. No usar información de salud ni documentos reales en esta demostración.

## Evidencias que necesitan acciones humanas o infraestructura

- GitHub CLI autorizado y repo preparado; Eva/Waldir todavía deben aceptar sus invitaciones Write. Ver GITHUB_ESTADO.md.
- Revisar y aprobar los casos de uso con el docente, como exige la diapositiva XP p. 15.
- Confirmar fecha de entrega y disponibilidad; el cronograma es relativo y estimado.
- Gestionar las issues del equipo en el Project 1 de GitHub; no se necesita cuenta Microsoft 365.
- Ejecutar y firmar revisiones, pruebas cruzadas y auditoría. Nadie puede aprobar su propio PR.
- Desplegar un entorno de pruebas, validar backup/restauración y grabar la demostración móvil.

Consultar `evidencias/INDICE.md` y el reporte generado para distinguir **ejecutado**, **planificado**, **bloqueado** y **no aplicable**. No dar por terminado un requisito por tener solamente un documento o una pantalla.
