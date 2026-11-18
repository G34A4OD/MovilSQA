import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/document_repository.dart';
import '../domain/folder_repository.dart';
import 'documents_panel.dart';
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
    this.documents,
    this.pickDocumentBytes,
  });
  final FolderRepository repository;
  final String familyId;
  final bool isAdmin;
  final String currentUserId;
  final List<FolderPetOption> pets;
  final DocumentRepository? documents;
  final DocumentBytesPicker? pickDocumentBytes;
  @override
  State<FoldersPanel> createState() => _FoldersPanelState();
}

class _FoldersPanelState extends State<FoldersPanel> {
  static const _searchThreshold = 4;
  late final model = FolderViewModel(
    widget.repository,
    widget.familyId,
    isAdmin: widget.isAdmin,
  );
  final search = TextEditingController();
  String query = '';
  FolderRecord? selected;

  @override
  void initState() {
    super.initState();
    model.load();
  }

  @override
  void didUpdateWidget(covariant FoldersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAdmin != widget.isAdmin) {
      model.updatePermissions(isAdmin: widget.isAdmin);
    }
  }

  @override
  void dispose() {
    search.dispose();
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
      builder: (_) => _FolderDialog(isAdmin: widget.isAdmin, pets: widget.pets),
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
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar carpeta',
      message:
          '¿Eliminar «${folder.name}»? Se retirará del grupo. Confirma solo si está vacía.',
      confirmLabel: 'Eliminar carpeta',
      confirmKey: const Key('folder-delete-confirm'),
      icon: Icons.folder_delete_outlined,
    );
    if (ok && mounted) {
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
    builder: (context, _) {
      final text = Theme.of(context).textTheme;
      final showSearch = model.items.length > _searchThreshold;
      final needle = query.trim().toLowerCase();
      final folders = showSearch && needle.isNotEmpty
          ? model.items
                .where((f) => f.name.toLowerCase().contains(needle))
                .toList()
          : model.items;
      return SectionCard(
        icon: Icons.folder_outlined,
        tone: Tone.warning,
        title: 'Carpetas',
        subtitle: model.items.isEmpty
            ? null
            : '${model.items.length} '
                  '${model.items.length == 1 ? 'carpeta' : 'carpetas'}',
        refreshTooltip: 'Actualizar carpetas',
        onRefresh: model.load,
        busy: model.busy,
        message: model.message,
        children: [
          if (showSearch) ...[
            TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar carpeta',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          search.clear();
                          setState(() => query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: Space.xs),
          ],
          if (model.items.isEmpty && !model.busy)
            const EmptyState(
              compact: true,
              icon: Icons.create_new_folder_outlined,
              title: 'Crea una carpeta propia para organizar documentos.',
            )
          else if (folders.isEmpty && !model.busy)
            const EmptyState(
              compact: true,
              icon: Icons.search_off_rounded,
              title: 'Ninguna carpeta coincide con la búsqueda.',
            ),
          for (final (i, folder) in folders.indexed) ...[
            if (i > 0) const Divider(indent: 56),
            ListTile(
              contentPadding: EdgeInsets.zero,
              selected: selected?.id == folder.id,
              onTap: widget.documents == null
                  ? null
                  : () => setState(() => selected = folder),
              leading: IconTile(
                icon: folder.ownerKind == FolderOwnerKind.pet
                    ? Icons.pets_rounded
                    : folder.ownerUserId == widget.currentUserId
                    ? Icons.folder_rounded
                    : Icons.folder_shared_outlined,
                tone: folder.ownerKind == FolderOwnerKind.pet
                    ? Tone.success
                    : folder.ownerUserId == widget.currentUserId
                    ? Tone.warning
                    : Tone.info,
              ),
              title: Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
              subtitle: Text(_subtitle(folder)),
              trailing: _canManage(folder)
                  ? PopupMenuButton<String>(
                      enabled: !model.busy,
                      tooltip: 'Opciones de ${folder.name}',
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (action) async {
                        if (action == 'rename') {
                          await renameFolder(folder);
                        } else {
                          await deleteFolder(folder);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.drive_file_rename_outline),
                            title: Text('Renombrar'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Eliminar',
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
          if (selected != null && widget.documents != null) ...[
            const SizedBox(height: Space.sm),
            DocumentsPanel(
              key: ValueKey('docs-${selected!.id}'),
              repository: widget.documents!,
              folderId: selected!.id,
              folderName: selected!.name,
              canUpload: _canManage(selected!),
              pickBytes: widget.pickDocumentBytes,
            ),
          ],
          const SizedBox(height: Space.xs),
          OutlinedButton.icon(
            key: const Key('folder-create'),
            onPressed: model.busy ? null : createFolder,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Nueva carpeta'),
          ),
        ],
      );
    },
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('folder-name'),
            controller: name,
            maxLength: 100,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre de la carpeta',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
          ),
          if (widget.isAdmin && widget.pets.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            DropdownButtonFormField<FolderOwnerKind>(
              key: const Key('folder-owner-kind'),
              initialValue: kind,
              decoration: const InputDecoration(
                labelText: 'Titular',
                prefixIcon: Icon(Icons.person_pin_outlined),
              ),
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
            if (kind == FolderOwnerKind.pet) ...[
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<String>(
                key: const Key('folder-pet'),
                initialValue: petId ?? widget.pets.first.id,
                decoration: const InputDecoration(
                  labelText: 'Mascota',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
                items: [
                  for (final pet in widget.pets)
                    DropdownMenuItem(value: pet.id, child: Text(pet.name)),
                ],
                onChanged: (value) => setState(() => petId = value),
              ),
            ],
          ],
          InlineMessage(text: message, tone: Tone.danger),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('folder-rename'),
          controller: name,
          maxLength: 100,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.drive_file_rename_outline),
          ),
        ),
        InlineMessage(text: message, tone: Tone.danger),
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
