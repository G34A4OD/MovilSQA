import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
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
    builder: (context, _) {
      final text = Theme.of(context).textTheme;
      return SectionCard(
        icon: Icons.pets_outlined,
        tone: Tone.warning,
        title: 'Nuestras mascotas',
        refreshTooltip: 'Actualizar mascotas',
        onRefresh: model.load,
        busy: model.busy,
        message: model.message,
        children: [
          if (model.items.isEmpty && !model.busy)
            const EmptyState(
              compact: true,
              icon: Icons.pets_outlined,
              title: 'Aquí también hay lugar para las mascotas.',
            ),
          for (final (i, pet) in model.items.indexed) ...[
            if (i > 0) const Divider(indent: 56),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(name: pet.details.name, icon: Icons.pets_rounded),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.details.name, style: text.titleSmall),
                        const SizedBox(height: Space.xxs),
                        Wrap(
                          spacing: Space.xs,
                          runSpacing: Space.xxs,
                          children: [
                            StatusBadge(label: pet.details.species),
                            if (pet.details.birthDate != null)
                              StatusBadge(
                                label: 'Nacimiento: ${pet.details.birthDate}',
                                icon: Icons.cake_outlined,
                              ),
                          ],
                        ),
                        if (pet.details.notes.isNotEmpty) ...[
                          const SizedBox(height: Space.xxs),
                          Text(pet.details.notes, style: text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (widget.isAdmin)
                    PopupMenuButton<String>(
                      enabled: !model.busy,
                      tooltip: 'Opciones de ${pet.details.name}',
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await edit(pet);
                        } else {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Quitar mascota',
                            message:
                                '¿Eliminar a ${pet.details.name} de este grupo? Se retirará el acceso a sus documentos.',
                            confirmLabel: 'Quitar mascota',
                          );
                          if (ok && mounted) {
                            await model.delete(pet);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar mascota'),
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
                              'Quitar mascota',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          if (widget.isAdmin) ...[
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              onPressed: model.busy ? null : edit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir mascota'),
            ),
          ],
        ],
      );
    },
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

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(birth.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isBefore(now) ? current : now,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null && mounted) {
      birth.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Añadir mascota' : 'Editar mascota'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre de la mascota',
              prefixIcon: Icon(Icons.pets_outlined),
            ),
          ),
          TextField(
            controller: species,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Especie',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          TextField(
            controller: birth,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Nacimiento opcional (AAAA-MM-DD)',
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: IconButton(
                tooltip: 'Elegir fecha',
                onPressed: _pickBirth,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: notes,
            maxLength: 1000,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas',
              alignLabelWithHint: true,
            ),
          ),
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
