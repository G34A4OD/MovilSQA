import 'package:flutter/material.dart';
import '../domain/sheet_repository.dart';
import 'sheet_view_model.dart';

class SheetsPanel extends StatefulWidget {
  const SheetsPanel({
    super.key,
    required this.repository,
    required this.familyId,
  });
  final BudgetSheetRepository repository;
  final String familyId;
  @override
  State<SheetsPanel> createState() => _SheetsPanelState();
}

class _SheetsPanelState extends State<SheetsPanel> {
  late final model = SheetViewModel(widget.repository, widget.familyId);
  final name = TextEditingController();
  @override
  void initState() {
    super.initState();
    model.load();
  }

  @override
  void dispose() {
    name.dispose();
    model.dispose();
    super.dispose();
  }

  Future<String?> _ask(String title, {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mis hojas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Solo tú ves estas hojas. Ser admin del grupo no abre las de otra persona.',
        ),
        const SizedBox(height: 8),
        if (model.message != null) Text(model.message!),
        for (final sheet in model.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(sheet.name),
            subtitle: Text('Versión ${sheet.version}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Renombrar',
                  onPressed: model.busy
                      ? null
                      : () async {
                          final next = await _ask(
                            'Renombrar hoja',
                            initial: sheet.name,
                          );
                          if (next != null) {
                            await model.rename(sheet, next);
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: model.busy
                      ? null
                      : () async {
                          final confirmation = await _ask(
                            'Escribe «${sheet.name}» para eliminar',
                          );
                          if (confirmation != null) {
                            await model.delete(sheet, confirmation);
                          }
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: name,
          enabled: !model.busy,
          decoration: const InputDecoration(labelText: 'Nueva hoja'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: model.busy
              ? null
              : () async {
                  final ok = await model.create(name.text);
                  if (ok) {
                    name.clear();
                  }
                },
          child: Text(model.busy ? 'Guardando…' : 'Crear hoja'),
        ),
      ],
    ),
  );
}
