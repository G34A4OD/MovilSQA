# Pruebas SQL/RLS pendientes

Crear tests por identidad/familia/documentos/presupuesto con datos ficticios de dos grupos y varios roles. Probar RLS con roles/JWT de usuario; postgres/service_role que omite RLS no demuestra autorización. Cubrir SELECT/INSERT/UPDATE/DELETE/RPC, escalado, último admin concurrente, invitado pendiente, categoría usada y dueño de hoja. Storage/Auth requieren también tests SDK/end-to-end. No declarar SQL/pgTAP ejecutado sin entorno y logs.
