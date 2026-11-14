"""PERT/CPM over a dependency DAG; estimates, not recorded work."""
import csv
from pathlib import Path

root = Path(__file__).resolve().parents[1]
with (root/"planificacion/actividades.csv").open(encoding="utf-8",newline="") as stream:
    data = list(csv.DictReader(stream))
tasks = {row["id"]: dict(row) for row in data}
if len(tasks) != len(data):
    raise ValueError("IDs duplicados.")
order = []
remaining = set(tasks)
while remaining:
    available = [key for key in tasks if key in remaining and all(p in order for p in filter(None,tasks[key]["predecesoras"].split("|")))]
    if not available:
        raise ValueError("Ciclo o predecesora desconocida.")
    for key in available:
        task = tasks[key]
        o,m,p = [float(task[n]) for n in ("optimista","probable","pesimista")]
        if not 0 <= o <= m <= p:
            raise ValueError("Estimación inválida.")
        task["te"] = (o+4*m+p)/6
        task["sigma"] = (p-o)/6
        task["pred"] = list(filter(None,task["predecesoras"].split("|")))
        task["es"] = max((tasks[x]["ef"] for x in task["pred"]),default=0)
        task["ef"] = task["es"]+task["te"]
        order.append(key)
        remaining.remove(key)
duration = max(t["ef"] for t in tasks.values())
for key in reversed(order):
    t = tasks[key]
    successors = [other for other in tasks.values() if key in other["pred"]]
    t["lf"] = min((other["ls"] for other in successors),default=duration)
    t["ls"] = t["lf"]-t["te"]
    t["slack"] = t["ls"]-t["es"]
lines = ["# EDT, PERT y CPM · propuesta", "",
         "Unidad: días hábiles equivalentes por paquete. TE=(O+4M+P)/6; sigma=(P-O)/6.",
         "Cronograma relativo, no horas realizadas ni fecha de entrega confirmada.", "",
         "| ID / EDT | Entregable / dueño | Pred. | O/M/P | TE | Sigma | IT | FT | IL | FL | Holgura |",
         "|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|"]
for key in order:
    t = tasks[key]
    numbers = " | ".join(f"{t[n]:.2f}" for n in ("te","sigma","es","ef","ls","lf","slack"))
    predecessors = t["predecesoras"].replace("|", ", ")
    lines.append(f"| {key} / {t['edt']} | {t['entregable']} / {t['responsable']} | {predecessors} | {t['optimista']}/{t['probable']}/{t['pesimista']} | {numbers} |")
critical = [key for key in order if abs(tasks[key]["slack"]) < 1e-8]
lines += ["",f"Duración por dependencias: **{duration:g} días**. Ruta crítica: **{' -> '.join(critical)}**.", "",
          "CPM no nivela recursos. E y K comparten Eva; Todos requiere coordinación. Confirmar capacidad y dividir paquetes mayores a una semana. Tras acordar inicio/entrega, trasladar IT/FT a Planner con calendario hábil; día 0 no significa hoy.", "",
          "## EDT (100% del alcance)", "",
          "- 1.0 Gestión: repo, roles, Planner, cambios y seguimiento.",
          "- 2.1 CU/HU/requisitos; 2.2 esquema/API/seguridad; 2.3 mockups.",
          "- 3.1 Identidad; 3.2 grupos/admins; 3.3 parentescos/mascotas; 3.4 documentos; 3.5 presupuesto/CSV.",
          "- 4.1 pruebas/automatización; 4.2 manual/presentación; 4.3 auditoría/métricas/correctivas.",
          "- 5.1 staging, backup/rollback, release, APK y entrega.", "",
          "## Red", "", "~~~mermaid", "flowchart LR", " A --> B", " A --> C", " B --> D",
          " B --> E", " C --> E", " B --> F", " C --> F", " D --> G", " E --> H",
          " F --> H", " G --> H", " H --> I", " C --> K", " I --> J", " K --> J", "~~~", ""]
(root/"planificacion/PLAN.md").write_text("\n".join(lines),encoding="utf-8")
print(f"CPM: {duration:g} dias; criticas: {' -> '.join(critical)}")
