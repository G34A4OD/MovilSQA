import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/profile.dart';
import 'auth_view_model.dart';
import 'profile_view_model.dart';
import 'profile_editor.dart';
import '../../family/domain/family_repository.dart';
import '../../family/presentation/family_page.dart';

class AccountHome extends StatefulWidget {
  const AccountHome({
    super.key,
    required this.auth,
    required this.repository,
    required this.families,
  });
  final AuthViewModel auth;
  final ProfileRepository repository;
  final FamilyRepository families;
  @override
  State<AccountHome> createState() => _AccountHomeState();
}

class _AccountHomeState extends State<AccountHome> {
  late final model = ProfileViewModel(widget.repository);
  bool editing = false;
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

  void _openFamilies() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FamilyPage(
        repository: widget.families,
        profiles: widget.repository,
        reauthenticate: (password) =>
            widget.auth.repository.signIn(widget.auth.session!.email, password),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          BrandMark(size: 32),
          SizedBox(width: Space.sm - 2),
          Text('Mi Nido'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión en este dispositivo',
          onPressed: widget.auth.busy ? null : widget.auth.signOut,
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: Space.xs),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          if (!model.loaded) {
            return Center(
              child: model.busy
                  ? const CircularProgressIndicator()
                  : EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: model.message ?? 'Carga tu perfil',
                      action: FilledButton.tonalIcon(
                        onPressed: model.load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ),
            );
          }
          if (editing || model.profile == null) {
            return Column(
              children: [
                if (model.profile != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: Space.xs),
                      child: TextButton.icon(
                        onPressed: () => setState(() => editing = false),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Volver'),
                      ),
                    ),
                  ),
                Expanded(
                  child: ProfileEditor(
                    model: model,
                    onSaved: () => setState(() => editing = false),
                  ),
                ),
              ],
            );
          }
          final p = model.profile!;
          final text = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.xs,
                  Space.lg,
                  Space.xxl,
                ),
                children: [
                  FadeSlideIn(
                    child: Row(
                      children: [
                        AppAvatar(name: p.details.fullName, size: 56),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, ${p.details.fullName}',
                                style: text.headlineSmall,
                              ),
                              Text(
                                widget.auth.session?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  FadeSlideIn(
                    index: 1,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: _openFamilies,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.lg),
                          child: Row(
                            children: [
                              const IconTile(
                                icon: Icons.diversity_1_outlined,
                                size: 48,
                              ),
                              const SizedBox(width: Space.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mis familias',
                                      style: text.titleMedium,
                                    ),
                                    Text(
                                      'Carpetas, presupuesto, mascotas y vínculos de cada hogar.',
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SectionHeader(title: 'Tu cuenta'),
                  FadeSlideIn(
                    index: 2,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const IconTile(
                                  icon: Icons.badge_outlined,
                                  tone: Tone.neutral,
                                ),
                                const SizedBox(width: Space.sm),
                                Expanded(
                                  child: Text(
                                    'Tu ID para invitaciones',
                                    style: text.titleSmall,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copiar ID',
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: p.publicId),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text('ID copiado.'),
                                          ),
                                        );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.sm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.md,
                                vertical: Space.sm,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                              child: SelectableText(
                                p.publicId,
                                style: moneyStyle(
                                  text.titleMedium,
                                ).copyWith(letterSpacing: 0.6),
                              ),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              'Comparte este ID con el administrador de tu familia.',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  FadeSlideIn(
                    index: 3,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const IconTile(
                              icon: Icons.person_outline_rounded,
                              tone: Tone.neutral,
                            ),
                            title: const Text('Editar mi perfil privado'),
                            subtitle: const Text(
                              'Nombre, CI, nacimiento, sangre y domicilio.',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => setState(() => editing = true),
                          ),
                          const Divider(indent: 72),
                          ListTile(
                            leading: const IconTile(
                              icon: Icons.logout_rounded,
                              tone: Tone.danger,
                            ),
                            title: Text(
                              'Cerrar sesión',
                              style: TextStyle(color: scheme.error),
                            ),
                            subtitle: const Text('Solo en este dispositivo.'),
                            onTap: widget.auth.busy
                                ? null
                                : widget.auth.signOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                  InlineMessage(text: widget.auth.message, tone: Tone.danger),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
