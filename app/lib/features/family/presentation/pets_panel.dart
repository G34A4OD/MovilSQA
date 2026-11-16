import 'package:flutter/material.dart';
import '../domain/pet_repository.dart';
import 'pet_view_model.dart';

class PetsPanel extends StatefulWidget {
  const PetsPanel({
    super.key,
    required this.repository,
    required this.familyId,
    required this.isAdmin,
  });
  final PetRepository repository;
  final String familyId;
  final bool isAdmin;
  @override
  State<PetsPanel> createState() => _PetsPanelState();
}

class _PetsPanelState extends State<PetsPanel> {
  late final model = PetViewModel(widget.repository, widget.familyId);
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

  Future<void> edit([PetRecord? existing]) async {
    final input = await showDialog<PetInput>(
      context: context,
      builder: (_) => _PetDialog(existing: existing),
    );
    if (input != null && mounted) {
      await model.save(input, existing: existing);
    }
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
                const Icon(Icons.pets_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nuestras mascotas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar mascotas',
                  onPressed: model.busy ? null : model.load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (model.busy) const LinearProgressIndicator(),
            if (model.message != null) Text(model.message!),
            if (model.items.isEmpty && !model.busy)
              const Text('Aquí también hay lugar para las mascotas.'),
            for (final pet in model.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(pet.details.name),
                subtitle: Text(
                  [
                    pet.details.species,
                    if (pet.details.birthDate != null)
                      'Nacimiento: ${pet.details.birthDate}',
                    if (pet.details.notes.isNotEmpty) pet.details.notes,
                  ].join('\n'),
                ),
                trailing: widget.isAdmin
                    ? PopupMenuButton<String>(
                        enabled: !model.busy,
                        tooltip: 'Opciones de ${pet.details.name}',
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await edit(pet);
                          } else {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Quitar mascota'),
                                content: Text(
                                  '¿Eliminar a ${pet.details.name} de este grupo? Se retirará el acceso a sus documentos.',
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
                                    child: const Text('Quitar mascota'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && mounted) {
                              await model.delete(pet);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar mascota'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Quitar mascota'),
                          ),
                        ],
                      )
                    : null,
              ),
            if (widget.isAdmin)
              OutlinedButton.icon(
                onPressed: model.busy ? null : edit,
                icon: const Icon(Icons.add),
                label: const Text('Añadir mascota'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _PetDialog extends StatefulWidget {
  const _PetDialog({this.existing});
  final PetRecord? existing;
  @override
  State<_PetDialog> createState() => _PetDialogState();
}

class _PetDialogState extends State<_PetDialog> {
  late final name = TextEditingController(text: widget.existing?.details.name);
  late final species = TextEditingController(
    text: widget.existing?.details.species,
  );
  late final birth = TextEditingController(
    text: widget.existing?.details.birthDate,
  );
  late final notes = TextEditingController(
    text: widget.existing?.details.notes,
  );
  String? message;
  @override
  void dispose() {
    name.dispose();
    species.dispose();
    birth.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Añadir mascota' : 'Editar mascota'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nombre de la mascota',
            ),
          ),
          TextField(
            controller: species,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Especie'),
          ),
          TextField(
            controller: birth,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Nacimiento opcional (AAAA-MM-DD)',
            ),
          ),
          TextField(
            controller: notes,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notas'),
          ),
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
        onPressed: () {
          final input = PetInput(
            name: name.text,
            species: species.text,
            birthDate: birth.text.trim().isEmpty ? null : birth.text.trim(),
            notes: notes.text,
          );
          if (!input.isValid) {
            setState(() => message = 'Revisa nombre, especie y fecha.');
            return;
          }
          Navigator.pop(context, input);
        },
        child: const Text('Guardar mascota'),
      ),
    ],
  );
}
