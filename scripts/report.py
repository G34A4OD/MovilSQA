"""Build a Class XX report from real Flutter machine events."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument("directory", type=Path)
directory = parser.parse_args().directory
metadata = json.loads((directory / "metadata.json").read_text(encoding="utf-8-sig"))
events = []
raw = directory / "tests.jsonl"
if raw.exists():
    for line in raw.read_text(encoding="utf-8-sig", errors="replace").splitlines():
        try:
            event = json.loads(line)
            if isinstance(event, dict):
                events.append(event)
        except json.JSONDecodeError:
            pass  # Keep original non-JSON output in the raw evidence.
tests = {e["test"]["id"]: e["test"] for e in events if e.get("type") == "testStart"}
ended = {e["testID"]: e for e in events if e.get("type") == "testDone"}
errors = {}
for event in events:
    if event.get("type") == "error":
        errors.setdefault(event.get("testID"), []).append(
            str(event.get("error", "")) + "\n" + str(event.get("stackTrace", "")))
rows = []
for ident, test in tests.items():
    end = ended.get(ident)
    if test["name"].startswith("loading ") or (end and end.get("hidden")):
        continue
    result = "incomplete" if not end else ("skipped" if end.get("skipped") else end.get("result", "unknown"))
    start = next((e.get("time", 0) for e in events if e.get("type") == "testStart" and e["test"]["id"] == ident), 0)
    rows.append({"name": test["name"], "result": result,
                 "tc": sorted(set(re.findall(r"TC-[A-Z]+-\d+", test["name"]))),
                 "hu": sorted(set(re.findall(r"HU-\d+", test["name"]))),
                 "error": "\n".join(errors.get(ident, [])),
                 "seconds": max(0, (end or {}).get("time", start)-start)/1000})
passed = sum(r["result"] == "success" for r in rows)
skipped = sum(r["result"] == "skipped" for r in rows)
failed = len(rows)-passed-skipped
done = next((e for e in reversed(events) if e.get("type") == "done"), {})
suite_ok = done.get("success") is True and bool(rows)
checks_ok = all(metadata.get(key) == 0 for key in ("pub_exit", "format_exit", "analyze_exit", "test_exit"))
ok = suite_ok and checks_ok and failed == 0
line_hits = {}
source_file = ""
coverage = directory / "lcov.info"
if coverage.exists():
    for line in coverage.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            source_file = line[3:]
        elif line.startswith("DA:"):
            number, hits, *_ = line[3:].split(",")
            key = (source_file, number)
            line_hits[key] = max(int(hits), line_hits.get(key, 0))
covered = sum(hits > 0 for hits in line_hits.values())
total_lines = len(line_hits)
domain_lines = {key: hits for key, hits in line_hits.items() if "/domain/" in key[0].replace("\\", "/") or key[0].replace("\\", "/").endswith("core/money.dart")}
domain_hits = sum(hits > 0 for hits in domain_lines.values())
domain_total = len(domain_lines)
domain_rate = f"{100*domain_hits/domain_total:.2f}%" if domain_total else "N/D"
rate = f"{100*passed/(passed+failed):.2f}%" if passed+failed else "N/D"
coverage_rate = f"{100*covered/total_lines:.2f}%" if total_lines else "N/D"
root = Path(__file__).resolve().parents[1]
fingerprint = hashlib.sha256()
for path in sorted([*root.glob("app/lib/**/*.dart"), *root.glob("app/test/**/*.dart"), root/"app/pubspec.yaml", root/"app/pubspec.lock"]):
    if path.is_file():
        fingerprint.update(path.relative_to(root).as_posix().encode())
        fingerprint.update(path.read_bytes().replace(b"\r\n", b"\n"))
summary = {"status": "PASS" if ok else "FAIL", "passed": passed, "failed": failed,
           "skipped": skipped, "total": len(rows), "suite_complete_success": suite_ok,
           "success_rate": rate, "coverage_hits": covered, "coverage_lines": total_lines,
           "coverage_rate": coverage_rate, "domain_coverage_rate": domain_rate,
           "domain_hits": domain_hits, "domain_lines": domain_total,
           "duration_seconds": done.get("time", 0)/1000,
           "source_sha256": fingerprint.hexdigest(), "metadata": metadata, "tests": rows}
(directory/"summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
lines = ["# Reporte automatizado · Nido", "",
         f"Resultado global: **{summary['status']}**. Alcance: unidad/widget de la base local; no API ni E2E móvil.", "",
         f"- Ejecución: {metadata.get('run_id')}", f"- Inicio UTC: {metadata.get('started_utc')}",
         f"- Commit base: {metadata.get('commit')}; árbol con cambios: {metadata.get('dirty')}",
         f"- SHA-256 de fuentes normalizadas a LF: {summary['source_sha256']}",
         f"- Entorno: {metadata.get('os')}; Flutter: {metadata.get('flutter')}",
         f"- Duración suite: {summary['duration_seconds']:.3f} s",
         f"- Pub/formato/análisis/tests (exit): {metadata.get('pub_exit')}/{metadata.get('format_exit')}/{metadata.get('analyze_exit')}/{metadata.get('test_exit')}", "",
         "| Total | Pasados | Fallidos/incompletos | Saltados | Tasa éxito (sin saltados) |",
         "|---:|---:|---:|---:|---:|",
         f"| {len(rows)} | {passed} | {failed} | {skipped} | {rate} |", "",
         f"Cobertura total instrumentada: {covered}/{total_lines} = {coverage_rate}.",
         f"Cobertura de dominio y dinero: {domain_hits}/{domain_total} = {domain_rate}. No es cobertura de requisitos ni de servidor.", "",
         "## Detalle y trazabilidad", "", "| Caso | TC | HU | Resultado |", "|---|---|---|---|"]
for row in rows:
    name = row["name"].replace("|", "/").replace("\n", " ")
    lines.append(f"| {name} | {', '.join(row['tc'])} | {', '.join(row['hu'])} | {row['result']} |")
lines += ["", "## Fallos y evidencia", "",
          "Logs: tests.jsonl, analyze.log, pub.log y format.log. Cobertura: lcov.info. Resultado JUnit: junit.xml.",
          "Errores de carga/compilación bloquean aunque no haya casos iniciados.",
          "Capturas UI/dispositivo: no generadas por esta suite; adjuntar desde el ejecutor E2E al realizar esas pruebas.", ""]
for ident, messages in errors.items():
    lines += [f"### Error testID {ident}", "", "~~~text", "\n".join(messages).replace("~~~", "---"), "~~~", ""]
lines += ["## Observaciones y conclusiones", "",
          "Verde valida solo los casos enumerados. Persistencia, permisos de servidor, dispositivo, carga y revisión humana permanecen pendientes.",
          "Si falla: clasificar código/test/entorno, vincular bug, corregir y reejecutar conservando evidencia.",
          "Flakiness, densidad de defectos y velocidad: N/D sin histórico/denominador/aceptación de sprint.", "",
          "Elaboración: ejecución automatizada. Revisor independiente y aceptación PO: pendientes de validación real.", ""]
(directory/"report.md").write_text("\n".join(lines), encoding="utf-8")
(directory/"report.html").write_text(
    '<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width">'
    '<title>Reporte SQA Nido</title><style>body{max-width:1100px;margin:40px auto;padding:24px;'
    'font:15px/1.6 system-ui;background:#f7f6f0;color:#244b41}pre{white-space:pre-wrap;overflow-wrap:anywhere}</style>'
    '<h1>Reporte SQA · Nido</h1><pre>'+html.escape("\n".join(lines))+'</pre></html>', encoding="utf-8")
suite = ET.Element("testsuite", name="Nido Flutter", tests=str(len(rows)), failures=str(failed), skipped=str(skipped), time=str(summary["duration_seconds"]))
for row in rows:
    case = ET.SubElement(suite, "testcase", name=row["name"], classname="flutter", time=str(row["seconds"]))
    if row["result"] == "skipped":
        ET.SubElement(case, "skipped")
    elif row["result"] != "success":
        ET.SubElement(case, "failure", message=row["result"]).text = row["error"]
if not suite_ok:
    ET.SubElement(suite, "system-err").text = "Suite incompleta/fallida; ver tests.jsonl."
ET.ElementTree(suite).write(directory/"junit.xml", encoding="utf-8", xml_declaration=True)
print(json.dumps({key: summary[key] for key in ("status", "total", "passed", "failed", "skipped", "coverage_rate")}))
raise SystemExit(0 if ok else 1)
