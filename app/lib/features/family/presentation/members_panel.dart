import 'package:flutter/material.dart';
import '../domain/family_repository.dart';
import 'family_view_model.dart';

class MembersPanel extends StatelessWidget {
  const MembersPanel({super.key, required this.model, required this.family});
  final FamilyViewModel model;
  final FamilyRecord family;
  Future<bool> confirm(BuildContext context, String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Miembros de la familia',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Text('Administración y parentesco son independientes.'),
      for (final member in model.members)
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(member.fullName),
            subtitle: Text(member.isAdmin ? 'Administrador' : 'Miembro'),
            trailing: family.isAdmin
                ? PopupMenuButton<String>(
                    enabled: !model.busy,
                    tooltip: 'Acciones de ${member.fullName}',
                    onSelected: (action) async {
                      if (action == 'admin') {
                        if (await confirm(
                          context,
                          member.isAdmin
                              ? 'Quitar administración'
                              : 'Hacer administrador',
                          '¿Confirmas el cambio de administración de ${member.fullName}?',
                        )) {
                          await model.setAdmin(family, member, !member.isAdmin);
                        }
                      } else if (await confirm(
                        context,
                        'Quitar del grupo',
                        '¿Retirar a ${member.fullName} de ${family.name}? Perderá acceso al grupo.',
                      )) {
                        await model.remove(family, member);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'admin',
                        child: Text(
                          member.isAdmin
                              ? (member.userId == model.repository.currentUserId
                                    ? 'Dejar de ser administrador'
                                    : 'Quitar administración')
                              : 'Hacer administrador',
                        ),
                      ),
                      if (member.userId != model.repository.currentUserId)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Quitar del grupo'),
                        ),
                    ],
                  )
                : null,
          ),
        ),
      TextButton.icon(
        onPressed: model.busy
            ? null
            : () async {
                if (await confirm(
                  context,
                  'Salir de la familia',
                  '¿Salir de ${family.name}? Perderás el acceso a este grupo y se retirarán tus datos compartidos.',
                )) {
                  await model.leave(family);
                }
              },
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Salir del grupo'),
      ),
    ],
  );
}
