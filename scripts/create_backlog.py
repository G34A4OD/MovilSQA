"""Generate the proposed backlog from the requirements catalog."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
milestones = ["S1 - Base e identidad", "S2 - Familia y archivos", "S3 - Presupuesto e integración", "S4 - Calidad y entrega"]
reviewers = {"Gerardo": "Waldir", "Eva": "Gerardo", "Waldir": "Eva"}
def item(ident, edt, title, owner, sprint, criteria, depends=(), points=3, priority="P0"):
    return dict(id=ident, edt=edt, title=title, owner=owner, reviewer=reviewers[owner], milestone=milestones[sprint-1], priority=priority, points=points, depends_on=list(depends), criteria=criteria)
items = [item("PREP-01", "1.0", "Preparar base, contrato y plan SQA", "Gerardo", 1,
              ["Base Flutter y tests reales", "Contrato, reparto y Test Plan revisables", "CI y evidencia, sin simular revisión de compañeros"])]
dependencies = {1:["PREP-01"],2:["HU-01"],3:["HU-01"],4:["HU-02","HU-03"],5:["HU-04"],6:["HU-05"],7:["HU-03"],8:["HU-03"],9:["HU-08"],10:["HU-09","HU-07"],11:["HU-03"],12:["HU-11"],13:["HU-12"],14:["HU-13"],15:["HU-14"]}
for line in (root/"docs/REQUISITOS.md").read_text(encoding="utf-8").splitlines():
    if not line.startswith("| RF-"):
        continue
    ident, edt, requirement, owner = [part.strip() for part in line.strip("|").split("|")]
    hu = re.search(r"HU-(\d+)", ident).group(0)
    number = int(hu.split("-")[1])
    sprint = 1 if number <= 2 else 2 if number in (3,4,5,8,9,11,12) else 3
    points = 8 if number == 9 else 5 if number in (1,5,6,13) else 3
    criteria = [requirement, "Tests positivos y negativos con TC/HU, Flutter/Supabase/RLS y evidencia", "Revisión cruzada, CI y aceptación real antes de Done"]
    if points == 8:
        criteria.insert(0, "Dividir en subissues de 1-3 días: carga, cuarentena/escaneo, consulta/edición y descarga")
    title = requirement.split(". ")[0]
    if len(title) > 100:
        title = title[:97] + "..."
    items.append(item(hu, edt, title, owner, sprint, criteria, dependencies[number], points,
                      "P1" if number in (6,7,8,10,12) else "P0"))
items += [
    item("QA-01","4.1","Comparar herramientas y preparar presentación","Eva",1,
         ["4 herramientas web y 4 móvil: tres abiertas y una comercial en cada matriz",
          "Matriz Word/Excel, presentación breve, fuentes oficiales y flujo CI",
          "Piloto real y justificación Clase XIX"],["PREP-01"],3,"P1"),
    item("QA-02","4.2","Ejecutar E2E, accesibilidad y reporte móvil","Eva",4,
         ["Flujo Flutter/Auth/RLS/RPC/Storage real en Android; iOS explícito",
          "Logs, capturas de fallos, metadatos y TC/HU Clase XX",
          "Exploración, 200% texto, red y segundo plano"],["HU-09","HU-15","HU-06"],5),
    item("QA-03","4.3","Medir calidad y auditar cada sprint","Waldir",4,
         ["Planner/CPM y métricas con denominador real",
          "Auditoría cruzada, correctivas y revalidación",
          "Carga staging p95/error rate; no inventar resultados"],["QA-02"],3,"P1"),
    item("OPS-01","5.1","Preparar entrega y release revisado","Gerardo",4,
         ["Backup/restauración y rollback probados",
          "PR develop a main, tag y APK checksum tras revisión",
          "Índice de evidencias y participación real de los tres"],["QA-03"])
]
(root/"planificacion").mkdir(exist_ok=True)
(root/"planificacion/backlog.json").write_text(json.dumps(items,indent=2,ensure_ascii=False),encoding="utf-8")
print(f"{len(items)} paquetes propuestos; validar y dividir antes de Ready.")
