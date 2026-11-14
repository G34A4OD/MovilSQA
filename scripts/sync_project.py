"""Organize existing Nido issues in the selected Project without duplicates."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OWNER = "G34A4OD"
PROJECT = "1"
def gh(*args):
    return subprocess.check_output(["gh", *args], text=True, encoding="utf-8").strip()
def read(*args):
    return json.loads(gh(*args))

project = read("project", "view", PROJECT, "--owner", OWNER, "--format", "json")
fields = {f["name"]: f for f in read("project", "field-list", PROJECT, "--owner", OWNER, "--format", "json")["fields"]}
for name, kind in [("Responsable","SINGLE_SELECT"),("Revisor SQA","SINGLE_SELECT"),
                   ("EDT","TEXT"),("HU / paquete","TEXT"),("Sprint SQA","TEXT"),("Dependencias","TEXT")]:
    if name not in fields:
        args = ["project","field-create",PROJECT,"--owner",OWNER,"--name",name,"--data-type",kind,"--format","json"]
        if kind == "SINGLE_SELECT":
            args += ["--single-select-options","Gerardo,Eva,Waldir"]
        fields[name] = read(*args)
items = read("project","item-list",PROJECT,"--owner",OWNER,"--limit","1000","--format","json")["items"]
by_url = {i.get("content",{}).get("url"): i for i in items}
backlog = json.loads((ROOT/"planificacion/backlog.json").read_text(encoding="utf-8"))
mapping = {x["id"]: x for x in json.loads((ROOT/"planificacion/github-map.json").read_text(encoding="utf-8"))}
records = []
for task in backlog:
    issue = mapping[task["id"]]
    item = by_url.get(issue["url"])
    if not item:
        item = read("project","item-add",PROJECT,"--owner",OWNER,"--url",issue["url"],"--format","json")
        by_url[issue["url"]] = item
    values = []
    def text_value(field, value):
        values.append((fields[field]["id"], "{text:"+json.dumps(value,ensure_ascii=False)+"}"))
    def select_value(field, value):
        options = {o["name"]:o["id"] for o in fields[field]["options"]}
        values.append((fields[field]["id"], "{singleSelectOptionId:"+json.dumps(options[value])+"}"))
    select_value("Responsable",task["owner"])
    select_value("Revisor SQA",task["reviewer"])
    text_value("EDT",task["edt"])
    text_value("HU / paquete",task["id"])
    text_value("Sprint SQA",task["milestone"])
    text_value("Dependencias",", ".join(task["depends_on"]) or "Ninguna")
    select_value("Priority",task["priority"])
    values.append((fields["Estimate"]["id"], "{number:"+str(task["points"])+"}"))
    if task["id"] == "PREP-01" and item.get("status") in (None,"Backlog","Ready","In progress"):
        select_value("Status","In review")
    elif not item.get("status"):
        select_value("Status","Backlog")
    operations = []
    for index,(field,value) in enumerate(values):
        payload = {"projectId":project["id"],"itemId":item["id"],"fieldId":field}
        args = ",".join(key+":"+json.dumps(val) for key,val in payload.items())
        operations.append(f'f{index}:updateProjectV2ItemFieldValue(input:{{{args},value:{value}}}){{projectV2Item{{id}}}}')
    gh("api","graphql","-f","query=mutation{"+ " ".join(operations)+"}")
    records.append(dict(id=task["id"],issue=issue["number"],item_id=item["id"],owner=task["owner"],reviewer=task["reviewer"]))
    print(f"{task['id']} #{issue['number']} -> {task['owner']} / {task['reviewer']}",flush=True)
(ROOT/"planificacion/project-map.json").write_text(json.dumps(dict(project_url=project["url"],project_id=project["id"],items=records),indent=2,ensure_ascii=False)+"\n",encoding="utf-8",newline="\n")
