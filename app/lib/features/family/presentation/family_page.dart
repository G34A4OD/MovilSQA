import 'package:flutter/material.dart';
import '../../identity/domain/profile.dart';
import '../domain/family_repository.dart';
import 'family_view_model.dart';
import 'invitations_panel.dart';
import 'members_panel.dart';
import 'package:uuid/uuid.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({
    super.key,
    required this.repository,
    required this.profiles,
    required this.reauthenticate,
  });
  final FamilyRepository repository;
  final ProfileRepository profiles;
  final Future<void> Function(String password) reauthenticate;
  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  late final model = FamilyViewModel(widget.repository);
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

  Future<String?> nameDialog(String title, {String initial = ''}) async {
    final input = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: input,
          maxLength: 100,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de la familia'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    // Dispose after the closing route transition has finished using its fields.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    input.dispose();
    return value;
  }

  Future<void> deleteFamily(FamilyRecord f) async {
    final confirmation = TextEditingController();
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Se retirará el acceso de todos. Escribe «${f.name}» y confirma tu contraseña.',
              ),
              TextField(
                controller: confirmation,
                decoration: const InputDecoration(labelText: 'Nombre exacto'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Tu contraseña'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar grupo'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.reauthenticate(password.text);
        if (mounted) await model.delete(f, confirmation.text);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se confirmó tu identidad. No se eliminó el grupo.',
              ),
            ),
          );
        }
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    confirmation.dispose();
    password.dispose();
  }

  Future<void> shareProfile(FamilyRecord f) async {
    final fields = <String>{};
    try {
      fields.addAll(await widget.profiles.sharedFields(f.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo cargar tu consentimiento actual. Recarga e intenta de nuevo.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final labels = {
      'blood_type': 'Tipo de sangre',
      'identity_card': 'Carnet de identidad',
      'birth_date': 'Fecha de nacimiento',
      'address': 'Domicilio',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Compartir mi información'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solo los campos marcados serán visibles para ${f.name}. Sin marcas, retiras lo compartido.',
              ),
              ...labels.entries.map(
                (e) => CheckboxListTile(
                  title: Text(e.value),
                  value: fields.contains(e.key),
                  onChanged: (v) => setDialog(() {
                    if (v == true) {
                      fields.add(e.key);
                    } else {
                      fields.remove(e.key);
                    }
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar consentimiento'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await model.run(
        () => widget.profiles.share(
          f.id,
          fields.toList()..sort(),
          const Uuid().v4(),
        ),
      );
      if (mounted && model.message == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias de información compartida guardadas.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final f = model.selected;
      return Scaffold(
        appBar: AppBar(
          title: Text(f?.name ?? 'Mis familias'),
          leading: f == null
              ? null
              : IconButton(
                  tooltip: 'Volver a mis familias',
                  onPressed: model.back,
                  icon: const Icon(Icons.arrow_back),
                ),
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: model.busy ? null : model.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (model.busy) const LinearProgressIndicator(),
              if (model.message != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(model.message!),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: f == null
                      ? [
                          Text(
                            'Cada hogar, su espacio',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Puedes pertenecer a más de un grupo familiar.',
                          ),
                          const SizedBox(height: 16),
                          for (final family in model.families)
                            Card(
                              child: ListTile(
                                title: Text(family.name),
                                subtitle: Text(
                                  family.isAdmin ? 'Administrador' : 'Miembro',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: model.busy
                                    ? null
                                    : () => model.select(family),
                              ),
                            ),
                          if (model.families.isEmpty && !model.busy)
                            const Text('Todavía no perteneces a un grupo.'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: model.busy
                                ? null
                                : () async {
                                    final name = await nameDialog(
                                      'Crear familia',
                                    );
                                    if (name != null && mounted) {
                                      await model.create(name);
                                    }
                                  },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear familia'),
                          ),
                          InvitationsPanel(
                            key: const ValueKey('received'),
                            repository: widget.repository.invitations,
                            onChanged: model.load,
                          ),
                        ]
                      : [
                          Text(
                            'Nuestro hogar',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          if (f.isAdmin)
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: model.busy
                                      ? null
                                      : () async {
                                          final name = await nameDialog(
                                            'Editar familia',
                                            initial: f.name,
                                          );
                                          if (name != null && mounted) {
                                            await model.update(f, name);
                                          }
                                        },
                                  child: const Text('Editar nombre'),
                                ),
                                TextButton(
                                  onPressed: model.busy
                                      ? null
                                      : () => deleteFamily(f),
                                  child: const Text('Eliminar grupo'),
                                ),
                              ],
                            ),
                          if (f.isAdmin)
                            InvitationsPanel(
                              key: ValueKey('sent:${f.id}'),
                              repository: widget.repository.invitations,
                              familyId: f.id,
                              onChanged: model.load,
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: model.busy
                                ? null
                                : () => shareProfile(f),
                            icon: const Icon(Icons.privacy_tip_outlined),
                            label: const Text('Elegir qué datos comparto'),
                          ),
                          const SizedBox(height: 16),
                          MembersPanel(model: model, family: f),
                        ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
