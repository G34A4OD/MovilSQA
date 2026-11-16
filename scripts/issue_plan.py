"""Only update known managed plan wording; preserve user notes and checkboxes."""
import re

STACK_LINE = "Stack: Flutter + Supabase directo (Auth, PostgreSQL/RLS, RPC y Storage privado)."

def sync_plan_body(body):
    result = re.sub(r"(?m)^Stack: [^\n]*", STACK_LINE, body.replace("\r\n", "\n"), count=1)
    result = result.replace("Flujo UI/API/DB/archivos", "Flujo Flutter/Auth/RLS/RPC/Storage")
    result = result.replace("UI/API/DB", "Flutter/Supabase/RLS")
    result = re.sub(r"(?m)^(?:Planner|GitHub Projects):[^\n]*",
                    "GitHub Projects: https://github.com/users/G34A4OD/projects/1/views/1",result,count=1)
    return result.replace("Planner/CPM", "GitHub Projects/CPM").replace("prueba de servidor/dispositivo", "prueba de Supabase/dispositivo")
