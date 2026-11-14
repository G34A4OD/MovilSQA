"""Protect notes, progress and identities while synchronizing the plan."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from issue_plan import STACK_LINE, sync_plan_body

class IssuePlanTest(unittest.TestCase):
    def test_preserves_progress_identity_and_notes(self):
        original = ("<!-- nido:HU-09 -->\r\nDriver: Eva · Revisor: Gerardo\r\n"
                    "Stack: old architecture\r\n- [x] Subir archivo\r\n"
                    "- [ ] Probar UI/API/DB\r\nNota humana: no borrar #10\r\n")
        updated = sync_plan_body(original)
        self.assertIn(STACK_LINE, updated)
        for preserved in ("<!-- nido:HU-09 -->", "Driver: Eva · Revisor: Gerardo",
                          "- [x] Subir archivo", "Nota humana: no borrar #10"):
            self.assertIn(preserved, updated)
        self.assertIn("- [ ] Probar Flutter/Supabase/RLS", updated)

    def test_idempotent_and_full_e2e_flow(self):
        original = "Stack: previous\n- [ ] Flujo UI/API/DB/archivos real en Android\n"
        updated = sync_plan_body(original)
        self.assertIn("Flujo Flutter/Auth/RLS/RPC/Storage real", updated)
        self.assertEqual(sync_plan_body(updated), updated)

    def test_does_not_overwrite_second_stack_note(self):
        original = "Stack: old\n## Nota humana\nStack: opinión del revisor\n"
        self.assertIn("Stack: opinión del revisor", sync_plan_body(original))

    def test_unrelated_body_is_unchanged(self):
        original = "# Nota\n- [x] Revisado por Eva\nNada que actualizar.\n"
        self.assertEqual(sync_plan_body(original), original)

if __name__ == "__main__":
    unittest.main()
