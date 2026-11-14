# EDT, PERT y CPM · propuesta

Unidad: días hábiles equivalentes por paquete. TE=(O+4M+P)/6; sigma=(P-O)/6.
Cronograma relativo, no horas realizadas ni fecha de entrega confirmada.

| ID / EDT | Entregable / dueño | Pred. | O/M/P | TE | Sigma | IT | FT | IL | FL | Holgura |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| A / 2.1 | Requisitos y contrato / Todos |  | 1/2/3 | 2.00 | 0.33 | 0.00 | 2.00 | 0.00 | 2.00 | 0.00 |
| B / 2.2 | Esquema API y seguridad / Gerardo | A | 1/3/5 | 3.00 | 0.67 | 2.00 | 5.00 | 2.00 | 5.00 | 0.00 |
| C / 2.3 | Interfaz Material 3 y mockups / Eva | A | 1/2/3 | 2.00 | 0.33 | 2.00 | 4.00 | 7.00 | 9.00 | 5.00 |
| D / 3.1 | Identidad y sesión / Gerardo | B | 2/4/6 | 4.00 | 0.67 | 5.00 | 9.00 | 5.00 | 9.00 | 0.00 |
| E / 3.4 | Archivo familiar seguro / Eva | B, C | 2/4/6 | 4.00 | 0.67 | 5.00 | 9.00 | 9.00 | 13.00 | 4.00 |
| F / 3.5 | Presupuesto y CSV / Waldir | B, C | 2/4/6 | 4.00 | 0.67 | 5.00 | 9.00 | 9.00 | 13.00 | 4.00 |
| K / 4.2 | Manual y presentación / Eva | C | 1/2/3 | 2.00 | 0.33 | 4.00 | 6.00 | 16.00 | 18.00 | 12.00 |
| G / 3.2-3.3 | Grupos parentescos y mascotas / Gerardo | D | 2/4/6 | 4.00 | 0.67 | 9.00 | 13.00 | 9.00 | 13.00 | 0.00 |
| H / 4.1 | Integración y E2E / Todos | E, F, G | 1/3/5 | 3.00 | 0.67 | 13.00 | 16.00 | 13.00 | 16.00 | 0.00 |
| I / 4.3 | Regresión auditoría y correctivas / Todos | H | 1/2/3 | 2.00 | 0.33 | 16.00 | 18.00 | 16.00 | 18.00 | 0.00 |
| J / 5.1 | Entrega y release / Todos | I, K | 1/1/1 | 1.00 | 0.00 | 18.00 | 19.00 | 18.00 | 19.00 | 0.00 |

Duración por dependencias: **19 días**. Ruta crítica: **A -> B -> D -> G -> H -> I -> J**.

CPM no nivela recursos. E y K comparten Eva; Todos requiere coordinación. Confirmar capacidad y dividir paquetes mayores a una semana. Tras acordar inicio/entrega, trasladar IT/FT a Planner con calendario hábil; día 0 no significa hoy.

## EDT (100% del alcance)

- 1.0 Gestión: repo, roles, Planner, cambios y seguimiento.
- 2.1 CU/HU/requisitos; 2.2 esquema/API/seguridad; 2.3 mockups.
- 3.1 Identidad; 3.2 grupos/admins; 3.3 parentescos/mascotas; 3.4 documentos; 3.5 presupuesto/CSV.
- 4.1 pruebas/automatización; 4.2 manual/presentación; 4.3 auditoría/métricas/correctivas.
- 5.1 staging, backup/rollback, release, APK y entrega.

## Red

~~~mermaid
flowchart LR
 A --> B
 A --> C
 B --> D
 B --> E
 C --> E
 B --> F
 C --> F
 D --> G
 E --> H
 F --> H
 G --> H
 H --> I
 C --> K
 I --> J
 K --> J
~~~
