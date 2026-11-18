import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
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
      final visible = model.items
          .where(
            (r) =>
                names.containsKey(r.fromUserId) &&
                names.containsKey(r.toUserId),
          )
          .toList();
      return SectionCard(
        icon: Icons.account_tree_outlined,
        tone: Tone.success,
        title: 'Nuestros vínculos',
        refreshTooltip: 'Recargar árbol',
        onRefresh: model.load,
        busy: model.busy,
        message: model.message,
        children: [
          FamilyTree(members: widget.members, relationships: model.items),
          if (widget.family.isAdmin) ...[
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: model.busy || widget.members.length < 2 ? null : edit,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Asignar parentesco'),
            ),
          ],
          if (visible.isNotEmpty) const SizedBox(height: Space.xs),
          for (final r in visible)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const IconTile(
                icon: Icons.link_rounded,
                tone: Tone.neutral,
                size: 36,
              ),
              title: Text(
                '${names[r.fromUserId]} · ${r.label} ${names[r.toUserId]}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: widget.family.isAdmin
                  ? PopupMenuButton<String>(
                      enabled: !model.busy,
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await edit(r);
                        } else {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Quitar vínculo',
                            message:
                                'Se eliminará este parentesco. Las personas seguirán en la familia.',
                            confirmLabel: 'Quitar',
                            icon: Icons.link_off_rounded,
                          );
                          if (ok && mounted) {
                            await model.delete(r);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.link_off_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Quitar vínculo',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: person,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Persona',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            items: widget.members
                .map(
                  (m) => DropdownMenuItem(
                    value: m.userId,
                    child: Text(m.fullName, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => person = v!),
          ),
          const SizedBox(height: Space.sm),
          DropdownButtonFormField<FamilyRole>(
            initialValue: role,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Es…',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            items: FamilyRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: (v) => setState(() => role = v!),
          ),
          const SizedBox(height: Space.sm),
          DropdownButtonFormField<String>(
            initialValue: relative,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'De este familiar',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            items: widget.members
                .map(
                  (m) => DropdownMenuItem(
                    value: m.userId,
                    child: Text(m.fullName, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => relative = v!),
          ),
          InlineMessage(
            text: person == relative
                ? 'Elige dos personas distintas.'
                : 'Este vínculo no concede permisos de administrador.',
            tone: person == relative ? Tone.warning : Tone.info,
          ),
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
