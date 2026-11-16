import 'package:flutter/material.dart';
import '../domain/family_repository.dart';
import '../domain/relationship_repository.dart';
import 'relationship_view_model.dart';
import 'family_tree.dart';

class RelationshipsPanel extends StatefulWidget {
  const RelationshipsPanel({
    super.key,
    required this.repository,
    required this.family,
    required this.members,
  });
  final RelationshipRepository repository;
  final FamilyRecord family;
  final List<FamilyMember> members;
  @override
  State<RelationshipsPanel> createState() => _RelationshipsPanelState();
}

class _RelationshipsPanelState extends State<RelationshipsPanel> {
  late final model = RelationshipViewModel(widget.repository, widget.family.id);
  @override
  void initState() {
    super.initState();
    model.load();
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RelationshipsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members.map((m) => m.userId).join() !=
        widget.members.map((m) => m.userId).join()) {
      model.load();
    }
  }

  Future<void> edit([RelationshipRecord? existing]) async {
    final input = await showDialog<RelationshipInput>(
      context: context,
      builder: (_) =>
          _RelationshipDialog(members: widget.members, existing: existing),
    );
    if (input != null && mounted) {
      await model.save(input, existing: existing);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final names = {for (final m in widget.members) m.userId: m.fullName};
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nuestros vínculos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Recargar árbol',
                    onPressed: model.busy ? null : model.load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (model.busy) const LinearProgressIndicator(),
              if (model.message != null) Text(model.message!),
              FamilyTree(members: widget.members, relationships: model.items),
              if (widget.family.isAdmin)
                OutlinedButton.icon(
                  onPressed: model.busy || widget.members.length < 2
                      ? null
                      : edit,
                  icon: const Icon(Icons.add_link),
                  label: const Text('Asignar parentesco'),
                ),
              for (final r in model.items.where(
                (r) =>
                    names.containsKey(r.fromUserId) &&
                    names.containsKey(r.toUserId),
              ))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${names[r.fromUserId]} · ${r.label} ${names[r.toUserId]}',
                  ),
                  trailing: widget.family.isAdmin
                      ? PopupMenuButton<String>(
                          enabled: !model.busy,
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await edit(r);
                            } else {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Quitar vínculo'),
                                  content: const Text(
                                    'Se eliminará este parentesco. Las personas seguirán en la familia.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Quitar'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && mounted) {
                                await model.delete(r);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Quitar vínculo'),
                            ),
                          ],
                        )
                      : null,
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _RelationshipDialog extends StatefulWidget {
  const _RelationshipDialog({required this.members, this.existing});
  final List<FamilyMember> members;
  final RelationshipRecord? existing;
  @override
  State<_RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends State<_RelationshipDialog> {
  late String person =
      widget.existing?.fromUserId ?? widget.members.first.userId;
  late String relative = widget.existing?.toUserId ?? widget.members[1].userId;
  late FamilyRole role = FamilyRole.values.firstWhere(
    (r) => r.kind == (widget.existing?.kind ?? 'parent') && !r.reverse,
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Asignar parentesco'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: person,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Persona'),
            items: widget.members
                .map(
                  (m) => DropdownMenuItem(
                    value: m.userId,
                    child: Text(m.fullName),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => person = v!),
          ),
          DropdownButtonFormField<FamilyRole>(
            initialValue: role,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Es…'),
            items: FamilyRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: (v) => setState(() => role = v!),
          ),
          DropdownButtonFormField<String>(
            initialValue: relative,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'De este familiar'),
            items: widget.members
                .map(
                  (m) => DropdownMenuItem(
                    value: m.userId,
                    child: Text(m.fullName),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => relative = v!),
          ),
          const SizedBox(height: 12),
          const Text('Este vínculo no concede permisos de administrador.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: person == relative
            ? null
            : () => Navigator.pop(
                context,
                RelationshipInput(
                  personId: person,
                  relativeId: relative,
                  role: role,
                ),
              ),
        child: const Text('Guardar vínculo'),
      ),
    ],
  );
}
