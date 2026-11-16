import 'package:flutter/material.dart';
import '../domain/folder_repository.dart';
import 'folder_view_model.dart';

class FolderPetOption {
  const FolderPetOption({required this.id, required this.name});
  final String id;
  final String name;
}

class FoldersPanel extends StatefulWidget {
  const FoldersPanel({
    super.key,
    required this.repository,
    required this.familyId,
    required this.isAdmin,
    required this.currentUserId,
    this.pets = const [],
  });
  final FolderRepository repository;
  final String familyId;
  final bool isAdmin;
  final String currentUserId;
  final List<FolderPetOption> pets;
  @override
  State<FoldersPanel> createState() => _FoldersPanelState();
}

class _FoldersPanelState extends State<FoldersPanel> {
  late final model = FolderViewModel(
    widget.repository,
    widget.familyId,
    isAdmin: widget.isAdmin,
  );

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

  bool _canManage(FolderRecord folder) {
    if (widget.isAdmin) {
      return true;
    }
    return folder.ownerKind == FolderOwnerKind.human &&
        folder.ownerUserId == widget.currentUserId;
  }

  Future<void> createFolder() async {
    final input = await showDialog<FolderInput>(
      context: context,
      builder: (_) => _FolderDialog(
        isAdmin: widget.isAdmin,
        pets: widget.pets,
      ),
    );
    if (input != null && mounted) {
      await model.create(input);
    }
  }

  Future<void> renameFolder(FolderRecord folder) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: folder.name),
    );
    if (name != null && mounted) {
      await model.rename(folder, name);
    }
  }

  Future<void> deleteFolder(FolderRecord folder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carpeta'),
        content: Text(
          '¿Eliminar «${folder.name}»? Se retirará del grupo. Confirma solo si está vacía.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar carpeta'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await model.delete(folder);
    }
  }

  String _subtitle(FolderRecord folder) {
    if (folder.ownerKind == FolderOwnerKind.pet) {
      final pet = widget.pets.where((p) => p.id == folder.petId).firstOrNull;
      return pet == null ? 'Mascota' : 'Mascota · ${pet.name}';
    }
    return folder.ownerUserId == widget.currentUserId
        ? 'Tu carpeta'
        : 'Familiar';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Carpetas del grupo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar carpetas',
                  onPressed: model.busy ? null : model.load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (model.busy) const LinearProgressIndicator(),
            if (model.message != null) Text(model.message!),
            if (model.items.isEmpty && !model.busy)
              const Text('Crea una carpeta propia para organizar documentos.'),
            for (final folder in model.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                subtitle: Text(_subtitle(folder)),
                trailing: _canManage(folder)
                    ? PopupMenuButton<String>(
                        enabled: !model.busy,
                        tooltip: 'Opciones de ${folder.name}',
                        onSelected: (action) async {
                          if (action == 'rename') {
                            await renameFolder(folder);
                          } else {
                            await deleteFolder(folder);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Renombrar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      )
                    : null,
              ),
            OutlinedButton.icon(
              key: const Key('folder-create'),
              onPressed: model.busy ? null : createFolder,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Nueva carpeta'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FolderDialog extends StatefulWidget {
  const _FolderDialog({required this.isAdmin, required this.pets});
  final bool isAdmin;
  final List<FolderPetOption> pets;
  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  final name = TextEditingController();
  FolderOwnerKind kind = FolderOwnerKind.human;
  String? petId;
  String? message;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nueva carpeta'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('folder-name'),
            controller: name,
            maxLength: 100,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre de la carpeta'),
          ),
          if (widget.isAdmin && widget.pets.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<FolderOwnerKind>(
              key: const Key('folder-owner-kind'),
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Titular'),
              items: const [
                DropdownMenuItem(
                  value: FolderOwnerKind.human,
                  child: Text('Yo'),
                ),
                DropdownMenuItem(
                  value: FolderOwnerKind.pet,
                  child: Text('Mascota'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  kind = value;
                  if (kind == FolderOwnerKind.human) {
                    petId = null;
                  } else {
                    petId ??= widget.pets.first.id;
                  }
                });
              },
            ),
            if (kind == FolderOwnerKind.pet)
              DropdownButtonFormField<String>(
                key: const Key('folder-pet'),
                initialValue: petId ?? widget.pets.first.id,
                decoration: const InputDecoration(labelText: 'Mascota'),
                items: [
                  for (final pet in widget.pets)
                    DropdownMenuItem(value: pet.id, child: Text(pet.name)),
                ],
                onChanged: (value) => setState(() => petId = value),
              ),
          ],
          if (message != null) Text(message!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('folder-save'),
        onPressed: () {
          final input = FolderInput(
            name: name.text,
            ownerKind: kind,
            petId: kind == FolderOwnerKind.pet
                ? (petId ?? widget.pets.firstOrNull?.id)
                : null,
          );
          if (!input.isValid) {
            setState(
              () => message =
                  'Usa un nombre de 1 a 100 caracteres, sin rutas, y un titular válido.',
            );
            return;
          }
          Navigator.pop(context, input);
        },
        child: const Text('Crear carpeta'),
      ),
    ],
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});
  final String initial;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final name = TextEditingController(text: widget.initial);
  String? message;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Renombrar carpeta'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('folder-rename'),
          controller: name,
          maxLength: 100,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        if (message != null) Text(message!),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          final value = name.text.trim();
          if (value.isEmpty || value.length > 100) {
            setState(() => message = 'Nombre obligatorio, sin rutas.');
            return;
          }
          Navigator.pop(context, name.text);
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
