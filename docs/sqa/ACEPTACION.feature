# language: es
Característica: Reglas críticas de Nido
  # Especificación ATDD/BDD; no runner Gherkin configurado aún.
  # Equivalentes unitarios identificados en la matriz de trazabilidad.

  @HU-05 @TC-FAM-04
  Escenario: El último administrador conserva la responsabilidad
    Dado un grupo con un único administrador
    Cuando ese administrador intenta salir o renunciar
    Entonces la operación se rechaza sin cambiar la membresía
    Y se le indica que designe otro administrador

  @HU-04 @TC-FAM-02
  Escenario: Una invitación pendiente no da acceso
    Dado que una persona recibió una invitación a una familia
    Cuando intenta consultar documentos antes de aceptar
    Entonces las políticas RLS de Supabase no exponen documentos del grupo

  @HU-09 @TC-DOC-04
  Escenario: Salir de la familia revoca lectura
    Dado que un miembro podía leer un documento compartido
    Cuando abandona el grupo
    Entonces una nueva petición autenticada a Storage no obtiene el contenido
    Y esto no elimina una copia que el miembro ya hubiera descargado

  @HU-14 @TC-BUD-02
  Escenario: Balance anual exacto y aislado
    Dado un ingreso de 150 bolivianos y un egreso de 175 en enero de 2026
    Y un ingreso de 30 en diciembre de 2026
    Y un ingreso de 9000 en 2025
    Cuando consulto el año 2026
    Entonces enero muestra déficit de 25 y el año superávit de 5

  @HU-15 @TC-BUD-04
  Escenario: Descargar un año sin movimientos
    Dado que soy dueño de una hoja de un grupo al que pertenezco
    Cuando exporto un año sin movimientos
    Entonces descargo un CSV con doce meses y totales en cero
