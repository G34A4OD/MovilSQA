import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
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

  Future<String?> _ask(
    String title, {
    String initial = '',
    String? message,
    String confirmLabel = 'Guardar',
    bool destructive = false,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: destructive
              ? const IconTile(
                  icon: Icons.delete_outline_rounded,
                  tone: Tone.danger,
                  size: 48,
                )
              : null,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(message),
                const SizedBox(height: Space.md),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => SectionCard(
      icon: Icons.request_page_outlined,
      tone: Tone.success,
      title: 'Mis hojas',
      subtitle:
          'Solo tú ves estas hojas. Ser admin del grupo no abre las de otra persona.',
      busy: model.busy,
      message: model.message,
      children: [
        if (model.items.isEmpty && !model.busy)
          const EmptyState(
            compact: true,
            icon: Icons.request_page_outlined,
            title: 'Todavía no tienes hojas en este grupo.',
          ),
        for (final (i, sheet) in model.items.indexed) ...[
          if (i > 0) const Divider(indent: 56),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconTile(
              icon: Icons.table_chart_outlined,
              tone: Tone.success,
            ),
            title: Text(
              sheet.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
                          if (next != null && mounted) {
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
                            confirmLabel: 'Eliminar',
                            destructive: true,
                          );
                          if (confirmation != null && mounted) {
                            await model.delete(sheet, confirmation);
                          }
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: Space.xl),
        TextField(
          controller: name,
          enabled: !model.busy,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nueva hoja',
            helperText: 'Entre 2 y 100 caracteres.',
            prefixIcon: Icon(Icons.note_add_outlined),
          ),
        ),
        const SizedBox(height: Space.xs),
        FilledButton.icon(
          onPressed: model.busy
              ? null
              : () async {
                  final ok = await model.create(name.text);
                  if (ok && mounted) {
                    name.clear();
                  }
                },
          icon: const Icon(Icons.add_rounded),
          label: Text(model.busy ? 'Guardando…' : 'Crear hoja'),
        ),
      ],
    ),
  );
}
