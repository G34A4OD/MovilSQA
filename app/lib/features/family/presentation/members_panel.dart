import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/family_repository.dart';
import 'family_view_model.dart';

class MembersPanel extends StatelessWidget {
  const MembersPanel({super.key, required this.model, required this.family});
  final FamilyViewModel model;
  final FamilyRecord family;
  Future<bool> confirm(
    BuildContext context,
    String title,
    String text, {
    bool destructive = false,
    String confirmLabel = 'Confirmar',
  }) => showConfirmDialog(
    context,
    title: title,
    message: text,
    confirmLabel: confirmLabel,
    destructive: destructive,
    icon: destructive ? Icons.person_remove_outlined : Icons.shield_outlined,
  );

  @override
  Widget build(BuildContext context) => SectionCard(
    icon: Icons.groups_outlined,
    title: 'Miembros de la familia',
    subtitle: 'Administración y parentesco son independientes.',
    children: [
      for (final (i, member) in model.members.indexed) ...[
        if (i > 0) const Divider(indent: 56),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: AppAvatar(name: member.fullName),
          title: Text(
            member.fullName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                label: member.isAdmin ? 'Administrador' : 'Miembro',
                tone: member.isAdmin ? Tone.info : Tone.neutral,
              ),
            ),
          ),
          trailing: family.isAdmin
              ? PopupMenuButton<String>(
                  enabled: !model.busy,
                  tooltip: 'Acciones de ${member.fullName}',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) async {
                    if (action == 'admin') {
                      if (await confirm(
                            context,
                            member.isAdmin
                                ? 'Quitar administración'
                                : 'Hacer administrador',
                            '¿Confirmas el cambio de administración de ${member.fullName}?',
                          ) &&
                          context.mounted) {
                        await model.setAdmin(family, member, !member.isAdmin);
                      }
                    } else if (await confirm(
                          context,
                          'Quitar del grupo',
                          '¿Retirar a ${member.fullName} de ${family.name}? Perderá acceso al grupo.',
                          destructive: true,
                          confirmLabel: 'Quitar',
                        ) &&
                        context.mounted) {
                      await model.remove(family, member);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'admin',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          member.isAdmin
                              ? Icons.remove_moderator_outlined
                              : Icons.add_moderator_outlined,
                        ),
                        title: Text(
                          member.isAdmin
                              ? (member.userId == model.repository.currentUserId
                                    ? 'Dejar de ser administrador'
                                    : 'Quitar administración')
                              : 'Hacer administrador',
                        ),
                      ),
                    ),
                    if (member.userId != model.repository.currentUserId)
                      PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.person_remove_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Quitar del grupo',
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
      const SizedBox(height: Space.xs),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: destructiveTextStyle(context),
          onPressed: model.busy
              ? null
              : () async {
                  if (await confirm(
                        context,
                        'Salir de la familia',
                        '¿Salir de ${family.name}? Perderás el acceso a este grupo y se retirarán tus datos compartidos.',
                        destructive: true,
                        confirmLabel: 'Salir',
                      ) &&
                      context.mounted) {
                    await model.leave(family);
                  }
                },
          icon: const Icon(Icons.exit_to_app_rounded),
          label: const Text('Salir del grupo'),
        ),
      ),
    ],
  );
}
