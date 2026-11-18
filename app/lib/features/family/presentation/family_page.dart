import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/widgets.dart';
import '../../documents/presentation/folders_panel.dart';
import '../../budget/presentation/sheets_panel.dart';
import '../../identity/domain/profile.dart';
import '../domain/family_repository.dart';
import '../domain/pet_repository.dart';
import 'family_view_model.dart';
import 'invitations_panel.dart';
import 'members_panel.dart';
import 'relationships_panel.dart';
import 'pets_panel.dart';
import 'package:uuid/uuid.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({
    super.key,
    required this.repository,
    required this.profiles,
    required this.reauthenticate,
    this.invitationId,
  });
  final FamilyRepository repository;
  final String? invitationId;
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
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la familia',
            helperText: 'Entre 2 y 100 caracteres.',
            prefixIcon: Icon(Icons.cottage_outlined),
          ),
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
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: const DialogIcon(
            icon: Icons.warning_amber_rounded,
            tone: Tone.danger,
          ),
          title: const Text('Eliminar grupo', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Se retirará el acceso de todos. Escribe «${f.name}» y confirma tu contraseña.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.md),
                TextField(
                  controller: confirmation,
                  decoration: const InputDecoration(labelText: 'Nombre exacto'),
                ),
                const SizedBox(height: Space.sm),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Tu contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
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
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar grupo'),
            ),
          ],
        );
      },
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
      'blood_type': ('Tipo de sangre', Icons.bloodtype_outlined),
      'identity_card': ('Carnet de identidad', Icons.badge_outlined),
      'birth_date': ('Fecha de nacimiento', Icons.cake_outlined),
      'address': ('Domicilio', Icons.home_outlined),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          icon: const DialogIcon(icon: Icons.privacy_tip_outlined),
          title: const Text(
            'Compartir mi información',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solo los campos marcados serán visibles para ${f.name}. Sin marcas, retiras lo compartido.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.sm),
                ...labels.entries.map(
                  (e) => CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Space.xs,
                    ),
                    secondary: Icon(e.value.$2),
                    title: Text(e.value.$1),
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
    if (ok == true && mounted) {
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

  List<Widget> _familiesList(BuildContext context) => [
    const PageHeader(
      eyebrow: 'Familias',
      title: 'Cada hogar, su espacio',
      subtitle: 'Puedes pertenecer a más de un grupo familiar.',
    ),
    const SizedBox(height: Space.md),
    for (final (i, family) in model.families.indexed)
      FadeSlideIn(
        index: i,
        child: Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            leading: AppAvatar(name: family.name, size: 44),
            title: Text(
              family.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Space.xxs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: family.isAdmin ? 'Administrador' : 'Miembro',
                  tone: family.isAdmin ? Tone.info : Tone.neutral,
                  icon: family.isAdmin
                      ? Icons.shield_outlined
                      : Icons.person_outline_rounded,
                ),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: model.busy ? null : () => model.select(family),
          ),
        ),
      ),
    if (model.families.isEmpty && !model.busy)
      const Card(
        child: EmptyState(
          icon: Icons.diversity_1_outlined,
          title: 'Todavía no perteneces a un grupo.',
          message: 'Crea una familia o acepta una invitación recibida.',
        ),
      ),
    if (model.families.isEmpty && !model.busy && widget.invitationId != null)
      Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const IconTile(icon: Icons.badge_outlined, tone: Tone.info),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Tu ID para invitaciones',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.sm,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: SelectableText(
                  widget.invitationId!,
                  style: moneyStyle(
                    Theme.of(context).textTheme.titleMedium,
                  ).copyWith(letterSpacing: 0.6),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Comparte este ID con el administrador de la familia; cuando te invite, acepta en Mis invitaciones.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.invitationId!),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID copiado.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar ID'),
                ),
              ),
            ],
          ),
        ),
      ),
    const SizedBox(height: Space.sm),
    FilledButton.icon(
      onPressed: model.busy
          ? null
          : () async {
              final name = await nameDialog('Crear familia');
              if (name != null && mounted) {
                await model.create(name);
              }
            },
      icon: const Icon(Icons.add_rounded),
      label: const Text('Crear familia'),
    ),
    const SizedBox(height: Space.lg),
    InvitationsPanel(
      key: const ValueKey('received'),
      repository: widget.repository.invitations,
      onChanged: model.load,
    ),
  ];

  List<Widget> _familyDetail(BuildContext context, FamilyRecord f) {
    final text = Theme.of(context).textTheme;
    return [
      FadeSlideIn(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppAvatar(
                      name: f.name,
                      size: 52,
                      icon: Icons.cottage_outlined,
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Nuestro hogar',
                              style: text.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: Space.xxs),
                          Wrap(
                            spacing: Space.xs,
                            runSpacing: Space.xxs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusBadge(
                                label: f.isAdmin ? 'Administrador' : 'Miembro',
                                tone: f.isAdmin ? Tone.info : Tone.neutral,
                                icon: f.isAdmin
                                    ? Icons.shield_outlined
                                    : Icons.person_outline_rounded,
                              ),
                              if (model.members.isNotEmpty)
                                Text(
                                  '${model.members.length} '
                                  '${model.members.length == 1 ? 'miembro' : 'miembros'}',
                                  style: text.bodySmall,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (f.isAdmin) ...[
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      OutlinedButton.icon(
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
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar nombre'),
                      ),
                      TextButton.icon(
                        style: destructiveTextStyle(context),
                        onPressed: model.busy ? null : () => deleteFamily(f),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Eliminar grupo'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      const SectionHeader(title: 'Personas'),
      MembersPanel(model: model, family: f),
      if (f.isAdmin)
        InvitationsPanel(
          key: ValueKey('sent:${f.id}'),
          repository: widget.repository.invitations,
          familyId: f.id,
          onChanged: model.load,
        ),
      RelationshipsPanel(
        key: ValueKey('relationships:${f.id}'),
        repository: widget.repository.relationships,
        family: f,
        members: model.members,
      ),
      const SectionHeader(title: 'Archivo familiar'),
      _FamilyFoldersPanel(
        key: ValueKey('folders:${f.id}'),
        family: f,
        repository: widget.repository,
      ),
      const SectionHeader(title: 'Presupuesto'),
      SheetsPanel(
        key: ValueKey('sheets:${f.id}'),
        repository: widget.repository.sheets,
        familyId: f.id,
      ),
      const SectionHeader(title: 'Mascotas'),
      PetsPanel(
        key: ValueKey('pets:${f.id}'),
        repository: widget.repository.pets,
        familyId: f.id,
        isAdmin: f.isAdmin,
      ),
      const SectionHeader(title: 'Privacidad'),
      SectionCard(
        icon: Icons.privacy_tip_outlined,
        tone: Tone.neutral,
        title: 'Datos que compartes',
        subtitle: 'Tú decides qué ve este grupo de tu perfil privado.',
        children: [
          OutlinedButton.icon(
            onPressed: model.busy ? null : () => shareProfile(f),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Elegir qué datos comparto'),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final f = model.selected;
      return PopScope(
        canPop: f == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) model.back();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              f?.name ?? 'Mis familias',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: f == null
                ? null
                : IconButton(
                    tooltip: 'Volver a mis familias',
                    onPressed: model.back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            actions: [
              IconButton(
                tooltip: 'Recargar',
                onPressed: model.busy ? null : model.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: Space.xs),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                LoadingStrip(busy: model.busy),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: InlineMessage(text: model.message, tone: Tone.danger),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: model.load,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: AnimatedSwitcher(
                          duration: Motion.of(context, Motion.medium),
                          layoutBuilder: expandedSwitcherLayout,
                          child: SingleChildScrollView(
                            key: ValueKey(f?.id),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              Space.lg,
                              Space.sm,
                              Space.lg,
                              Space.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: f == null
                                  ? _familiesList(context)
                                  : _familyDetail(context, f),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FamilyFoldersPanel extends StatefulWidget {
  const _FamilyFoldersPanel({
    super.key,
    required this.family,
    required this.repository,
  });
  final FamilyRecord family;
  final FamilyRepository repository;
  @override
  State<_FamilyFoldersPanel> createState() => _FamilyFoldersPanelState();
}

class _FamilyFoldersPanelState extends State<_FamilyFoldersPanel> {
  List<FolderPetOption> pets = const [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void didUpdateWidget(covariant _FamilyFoldersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.family.id != widget.family.id ||
        oldWidget.family.isAdmin != widget.family.isAdmin) {
      _loadPets();
    }
  }

  Future<void> _loadPets() async {
    if (!widget.family.isAdmin) {
      if (mounted) {
        setState(() => pets = const []);
      }
      return;
    }
    try {
      final rows = await widget.repository.pets.list(widget.family.id);
      if (!mounted) {
        return;
      }
      setState(
        () => pets = [
          for (final PetRecord pet in rows)
            FolderPetOption(id: pet.id, name: pet.details.name),
        ],
      );
    } catch (_) {
      if (mounted) {
        setState(() => pets = const []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.repository.currentUserId;
    if (userId == null) {
      return const SizedBox.shrink();
    }
    return FoldersPanel(
      repository: widget.repository.folders,
      familyId: widget.family.id,
      isAdmin: widget.family.isAdmin,
      currentUserId: userId,
      pets: pets,
      documents: widget.repository.documents,
    );
  }
}
