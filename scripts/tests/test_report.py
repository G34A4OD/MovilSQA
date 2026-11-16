"""Contract tests for reporting: never turn missing/failed evidence green."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

REPORT = Path(__file__).resolve().parents[1]/"report.py"
class ReportTest(unittest.TestCase):
    def execute(self, events, check_exit=0):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            metadata = dict(run_id="synthetic-fixture",pub_exit=0,format_exit=check_exit,analyze_exit=0,test_exit=0)
            (directory/"metadata.json").write_text(json.dumps(metadata),encoding="utf-8")
            (directory/"tests.jsonl").write_text("\n".join(json.dumps(e) for e in events),encoding="utf-8")
            result = subprocess.run([sys.executable,str(REPORT),str(directory)],capture_output=True)
            summary = json.loads((directory/"summary.json").read_text(encoding="utf-8"))
            ET.parse(directory/"junit.xml")
            return result.returncode,summary,(directory/"report.html").read_text(encoding="utf-8")
    def test_pass_skip_and_non_event_json(self):
        events = [[], {"type":"testStart","test":{"id":1,"name":"TC-BUD-02 HU-14 saldo"}},
                  {"type":"testDone","testID":1,"result":"success","skipped":False},
                  {"type":"testStart","test":{"id":2,"name":"TC-UI-01 HU-13 saltado"}},
                  {"type":"testDone","testID":2,"result":"success","skipped":True},
                  {"type":"done","success":True,"time":2000}]
        code,summary,_ = self.execute(events)
        self.assertEqual((code,summary["passed"],summary["skipped"],summary["total"]),(0,1,1,2))
        self.assertEqual(summary["tests"][0]["hu"],["HU-14"])
    def test_failed_assertion_is_not_success_and_html_is_escaped(self):
        events = [{"type":"testStart","test":{"id":1,"name":"TC-BUD-02 HU-14 fallo"}},
                  {"type":"error","testID":1,"error":"<script>unsafe</script>"},
                  {"type":"testDone","testID":1,"result":"failure","skipped":False},
                  {"type":"done","success":False}]
        code,summary,html = self.execute(events)
        self.assertEqual((code,summary["failed"]),(1,1))
        self.assertIn("&lt;script&gt;",html)
        self.assertNotIn("<script>",html)
    def test_missing_done_is_failure(self):
        code,summary,_ = self.execute([{"type":"testStart","test":{"id":1,"name":"TC-UI-01 HU-13 incompleto"}}])
        self.assertEqual((code,summary["failed"]),(1,1))
    def test_compile_failure_without_cases_is_failure(self):
        events = [{"type":"testStart","test":{"id":1,"name":"loading broken.dart"}},
                  {"type":"error","testID":1,"error":"compile failed"},
                  {"type":"testDone","testID":1,"result":"error","hidden":False},
                  {"type":"done","success":False}]
        code,summary,_ = self.execute(events)
        self.assertEqual((code,summary["total"],summary["status"]),(1,0,"FAIL"))
    def test_format_failure_blocks_global_pass(self):
        events = [{"type":"testStart","test":{"id":1,"name":"TC-BUD-02 HU-14 pasa"}},
                  {"type":"testDone","testID":1,"result":"success"},
                  {"type":"done","success":True}]
        code,summary,_ = self.execute(events,check_exit=1)
        self.assertEqual((code,summary["passed"],summary["status"]),(1,1,"FAIL"))
if __name__ == "__main__":
    unittest.main()
