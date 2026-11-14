"""Idempotent labels/milestones/issues setup; never merge or approve."""
import argparse
import json
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--repo",default="G34A4OD/MovilSQA")
parser.add_argument("--gerardo",default="G34A4OD")
parser.add_argument("--eva",default="")
parser.add_argument("--waldir",default="")
parser.add_argument("--apply",action="store_true")
args = parser.parse_args()
if not re.fullmatch(r"[\w.-]+/[\w.-]+",args.repo):
    raise SystemExit("Repositorio inválido.")
handles = {"Gerardo":args.gerardo,"Eva":args.eva,"Waldir":args.waldir}
if any(value and not re.fullmatch(r"[A-Za-z0-9-]+",value) for value in handles.values()):
    raise SystemExit("Handle inválido.")
root = Path(__file__).resolve().parents[1]
items = json.loads((root/"planificacion/backlog.json").read_text(encoding="utf-8"))
if not args.apply:
    for item in items:
        print(f"{item['id']} [{item['edt']}] {item['owner']} / revisión {item['reviewer']}: {item['title']}")
    print("Solo lectura. --apply crea labels/milestones/issues; no ramas, merges, invitaciones o protecciones.")
    raise SystemExit(0)
def gh(*arguments):
    return subprocess.check_output(["gh",*arguments],text=True,encoding="utf-8").strip()
print("Cuenta activa:",gh("api","user","--jq",".login"))
for label in ["feature","movil","api","test","security","docs","gerardo","eva","waldir","priority:P0","priority:P1"]:
    gh("label","create",label,"--repo",args.repo,"--color","386653","--force")
milestones = json.loads(gh("api",f"repos/{args.repo}/milestones?state=all&per_page=100"))
for title in sorted(set(item["milestone"] for item in items)):
    if title not in {m["title"] for m in milestones}:
        gh("api","--method","POST",f"repos/{args.repo}/milestones","-f",f"title={title}",
           "-f","description=Iteración propuesta; fechas pendientes de confirmar")
existing = json.loads(gh("issue","list","--repo",args.repo,"--state","all","--limit","1000","--json","number,title,body,url"))
body_dir = root/"tmp/github-bodies"
body_dir.mkdir(parents=True,exist_ok=True)
result = []
for item in items:
    marker = f"<!-- nido:{item['id']} -->"
    found = [issue for issue in existing if marker in (issue.get("body") or "")]
    if len(found) > 1:
        raise SystemExit(f"Issues duplicadas para {item['id']}.")
    if found:
        issue = found[0]
        print("Existe:",issue["url"])
    else:
        criteria = "\n".join("- [ ] "+criterion for criterion in item["criteria"])
        body = f"""{marker}
## Entregable
{item['title']}

EDT: {item['edt']} · HU/paquete: {item['id']} · {item['points']} puntos propuestos
Driver: {item['owner']} · Revisor: {item['reviewer']}
Dependencias: {', '.join(item['depends_on']) or 'Ninguna'}
Plan: docs/sqa/TEST_PLAN.md · TC: docs/sqa/CASOS_PRUEBA.md
Contrato: docs/api/CONTRATO.md
Stack: Flutter + Laravel + PostgreSQL en Supabase y Storage privado.
Planner: pendiente de enlace real; tarea [EDT] #número Título.

## Aceptación
{criteria}
- [ ] DoR: CU/docente, mockup, contrato, datos y PERT revisados
- [ ] Tests positivos/negativos con TC/HU y reporte Clase XX
- [ ] Revisión cruzada real, CI verde y evidencia antes de Done

No hay aprobación humana ni prueba de servidor/dispositivo hasta adjuntar evidencia.
"""
        body_path = body_dir/(item["id"]+".md")
        body_path.write_text(body,encoding="utf-8")
        arguments = ["issue","create","--repo",args.repo,"--title",f"[{item['edt']}] {item['id']} {item['title']}",
                     "--body-file",str(body_path),"--milestone",item["milestone"],
                     "--label",f"feature,movil,{item['owner'].lower()},priority:{item['priority']}"]
        if handles[item["owner"]]:
            arguments += ["--assignee",handles[item["owner"]]]
        url = gh(*arguments)
        issue = dict(number=int(url.split("/")[-1]),url=url)
        print("Creada:",url)
    result.append({key:item[key] for key in ("id","edt","owner","reviewer","milestone")} |
                  {"number":issue["number"],"url":issue["url"]})
    # Checkpoint each successful mutation so a partial failure is reviewable.
    (root/"planificacion/github-map.json").write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding="utf-8")
print("Mapa guardado. Eva/Waldir sin handle quedan identificados por label y texto; no asignados a una cuenta inventada.")
