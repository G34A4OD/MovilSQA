import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/connected_app.dart';
import 'core/secure_session_storage.dart';
import 'core/supabase_config.dart';
import 'core/widgets/widgets.dart';
import 'features/identity/data/supabase_auth_repository.dart';
import 'features/identity/data/supabase_profile_repository.dart';
import 'features/family/data/supabase_family_repository.dart';
import 'core/app_theme.dart';
import 'core/money.dart';
import 'demo/demo_data.dart';
import 'demo/demo_family.dart';
import 'features/budget/presentation/budget_page.dart';
import 'features/budget/presentation/budget_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('NIDO_DEMO')) {
    runApp(const NidoApp());
    return;
  }
  try {
    const config = SupabaseConfig.fromEnvironment;
    config.validate();
    final host = Uri.parse(config.url).host;
    final supabase = await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureSessionStorage(
          nidoSecureStorage,
          projectHost: host,
        ),
        pkceAsyncStorage: SecurePkceStorage(
          nidoSecureStorage,
          projectHost: host,
        ),
        detectSessionInUriPredicate: (uri) =>
            uri.scheme == 'nido' &&
            uri.host == 'auth' &&
            uri.path == '/callback',
      ),
    );
    runApp(
      ConnectedNidoApp(
        auth: SupabaseAuthRepository(supabase.client),
        profiles: SupabaseProfileRepository(supabase.client),
        families: SupabaseFamilyRepository(supabase.client),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Space.xl),
                child: EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'No se pudo iniciar Nido',
                  message:
                      'No se pudo iniciar Nido. Revisa la configuración pública de Supabase o vuelve a abrir la aplicación.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NidoApp extends StatelessWidget {
  const NidoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nido · Tu familia',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: const FamilyHome(),
  );
}

class FamilyHome extends StatefulWidget {
  const FamilyHome({super.key});
  @override
  State<FamilyHome> createState() => _FamilyHomeState();
}

class _FamilyHomeState extends State<FamilyHome> {
  late final BudgetViewModel budget = createDemoBudget();
  final family = DemoFamily();
  int section = 0;
  @override
  void dispose() {
    budget.dispose();
    family.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(size: 34),
            const SizedBox(width: Space.sm - 2),
            Text(
              'nido',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: IconButton(
              tooltip: 'Ver mi familia',
              onPressed: () => setState(() => section = 1),
              icon: const AppAvatar(
                name: 'Familia',
                size: 38,
                icon: Icons.person_outline_rounded,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.medium),
                    switchInCurve: Motion.curve,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: expandedSwitcherLayout,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(section),
                      child: switch (section) {
                        1 => _FamilyPreview(family: family),
                        2 => BudgetPage(model: budget),
                        3 => const _DocumentsPreview(),
                        _ => _Overview(
                          budget: budget,
                          onNavigate: (v) => setState(() => section = v),
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.0,
          child: NavigationBar(
            selectedIndex: section,
            onDestinationSelected: (v) => setState(() => section = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Familia',
              ),
              NavigationDestination(
                key: Key('budget-tab'),
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Presupuesto',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'Documentos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.budget, required this.onNavigate});
  final BudgetViewModel budget;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.xxl,
      ),
      children: [
        const PageHeader(
          eyebrow: 'Inicio',
          title: 'Hola, familia',
          subtitle: 'Lo importante, un poquito más cerca.',
        ),
        const SizedBox(height: Space.lg),
        FadeSlideIn(
          child: ListenableBuilder(
            listenable: budget,
            builder: (context, _) {
              final month = budget.ledger.monthSummary(
                budget.year,
                budget.month,
              );
              return Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => onNavigate(2),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const IconTile(
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo de ${monthNames[budget.month - 1].toLowerCase()}',
                                    style: text.bodySmall,
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatCents(month.balance),
                                      maxLines: 1,
                                      style: moneyStyle(text.headlineSmall),
                                    ),
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
                        const SizedBox(height: Space.md),
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                label: 'Ingresos',
                                value: formatCents(month.income),
                                icon: Icons.south_west_rounded,
                                tone: Tone.success,
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: StatTile(
                                label: 'Egresos',
                                value: formatCents(month.expense),
                                icon: Icons.north_east_rounded,
                                tone: Tone.danger,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: Space.xxl),
                        Text(
                          'Balance ${budget.year} · ${formatCents(budget.summary.balance)}',
                          style: moneyStyle(
                            text.bodyMedium,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Revisa y organiza el presupuesto del año',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SectionHeader(title: 'Accesos rápidos'),
        FadeSlideIn(
          index: 1,
          child: Row(
            children: [
              for (final (i, item) in const [
                (1, 'Familia', Icons.people_outline_rounded, Tone.info),
                (
                  2,
                  'Presupuesto',
                  Icons.account_balance_wallet_outlined,
                  Tone.success,
                ),
                (3, 'Documentos', Icons.folder_outlined, Tone.warning),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: Space.sm),
                Expanded(
                  child: _QuickAction(
                    label: item.$2,
                    icon: item.$3,
                    tone: item.$4,
                    onTap: () => onNavigate(item.$1),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SectionHeader(title: 'Tu hogar, organizado'),
        FadeSlideIn(
          index: 2,
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _HomeRow(
                  leading: const _AvatarStack(
                    names: ['Elena Rivera', 'Luis Rivera', 'Ana Rivera'],
                  ),
                  title: 'Casa Rivera',
                  subtitle: '4 familiares y una mascota',
                  onTap: () => onNavigate(1),
                ),
                const Divider(indent: Space.md, endIndent: Space.md),
                _HomeRow(
                  leading: const IconTile(
                    icon: Icons.folder_outlined,
                    tone: Tone.warning,
                  ),
                  title: 'Archivo familiar',
                  subtitle: 'Un espacio para cada documento',
                  onTap: () => onNavigate(3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        FadeSlideIn(
          index: 3,
          child: Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primaryContainer, scheme.surface],
              ),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.diversity_1_outlined, color: scheme.primary),
                const SizedBox(height: Space.sm),
                Text(
                  'Un lugar para cuidar lo nuestro.',
                  style: text.titleLarge,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Personas, documentos y planes de cada mes, en un solo lugar.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.md),
                FilledButton.tonalIcon(
                  onPressed: () => onNavigate(1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ver mi familia'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Tone tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Space.md,
          horizontal: Space.xs,
        ),
        child: Column(
          children: [
            IconTile(icon: icon, tone: tone, size: 44),
            const SizedBox(height: Space.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeRow extends StatelessWidget {
  const _HomeRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Space.md,
      vertical: Space.xxs,
    ),
    leading: leading,
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.names});
  final List<String> names;
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      width: 28.0 + 16 * (names.length - 1),
      height: 32,
      child: Stack(
        children: [
          for (final (i, name) in names.indexed)
            Positioned(
              left: i * 16.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 2),
                ),
                child: AppAvatar(name: name, size: 28),
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilyPreview extends StatefulWidget {
  const _FamilyPreview({required this.family});
  final DemoFamily family;
  @override
  State<_FamilyPreview> createState() => _FamilyPreviewState();
}

class _FamilyPreviewState extends State<_FamilyPreview> {
  final inviteId = TextEditingController();
  String? inviteError;

  @override
  void dispose() {
    inviteId.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _invite() {
    final error = widget.family.invite(inviteId.text);
    setState(() => inviteError = error);
    if (error == null) {
      inviteId.clear();
      _snack('Invitación enviada');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.family,
    builder: (context, _) => _content(context),
  );

  Widget _content(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final family = widget.family;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.xxl,
      ),
      children: [
        const PageHeader(
          eyebrow: 'Familia',
          title: 'Casa Rivera',
          subtitle: 'Cada persona tiene su lugar.',
        ),
        const SectionHeader(title: 'Unirte a una familia'),
        FadeSlideIn(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const IconTile(icon: Icons.badge_outlined),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          'Tu ID para invitaciones',
                          style: text.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar ID',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: DemoFamily.publicId),
                          );
                          if (mounted) _snack('ID copiado.');
                        },
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
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: SelectableText(
                      DemoFamily.publicId,
                      style: moneyStyle(
                        text.titleMedium,
                      ).copyWith(letterSpacing: 0.6),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Comparte este ID con el administrador de la familia; cuando te invite, acepta en Mis invitaciones.',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SectionHeader(title: 'Mis invitaciones'),
        FadeSlideIn(
          index: 1,
          child: Card(
            margin: EdgeInsets.zero,
            child: family.received.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: Icons.mark_email_read_outlined,
                    title: 'No hay invitaciones pendientes.',
                  )
                : Column(
                    children: [
                      for (final invitation in family.received)
                        Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppAvatar(name: invitation.family),
                                  const SizedBox(width: Space.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invitation.family,
                                          style: text.titleSmall,
                                        ),
                                        Text(
                                          'Te invita ${invitation.from}',
                                          style: text.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Space.sm),
                              Wrap(
                                spacing: Space.xs,
                                runSpacing: Space.xs,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      family.respond(invitation, accept: false);
                                      _snack('Invitación rechazada');
                                    },
                                    child: const Text('Rechazar'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      family.respond(invitation, accept: true);
                                      _snack(
                                        'Te uniste a ${invitation.family}',
                                      );
                                    },
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SectionHeader(title: 'Mis familias'),
        FadeSlideIn(
          index: 2,
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, name) in family.families.indexed) ...[
                  if (i > 0) const Divider(indent: 72),
                  ListTile(
                    leading: AppAvatar(name: name),
                    title: Text(name),
                    subtitle: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(
                        label: i == 0 ? 'Administradora' : 'Miembro',
                        tone: i == 0 ? Tone.info : Tone.neutral,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Miembros'),
        FadeSlideIn(
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, member) in const [
                  ('Elena Rivera', 'Madre', 'Administradora'),
                  ('Luis Rivera', 'Padre', 'Miembro'),
                  ('Ana Rivera', 'Hija', 'Miembro'),
                  ('Mateo Rivera', 'Hijo', 'Miembro'),
                ].indexed) ...[
                  if (i > 0) const Divider(indent: 72),
                  ListTile(
                    leading: AppAvatar(name: member.$1),
                    title: Text(member.$1),
                    subtitle: Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(member.$2),
                        StatusBadge(
                          label: member.$3,
                          tone: member.$3 == 'Administradora'
                              ? Tone.info
                              : Tone.neutral,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Vínculos'),
        FadeSlideIn(
          index: 1,
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                children: [
                  for (final line in const [
                    'Elena y Luis son pareja.',
                    'Son madre y padre de Ana y Mateo.',
                    'Ana y Mateo son hermanos.',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const IconTile(
                            icon: Icons.link_rounded,
                            tone: Tone.neutral,
                            size: 30,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(child: Text(line, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SectionHeader(title: 'También son familia'),
        const FadeSlideIn(
          index: 2,
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: AppAvatar(name: 'Luna', icon: Icons.pets_rounded),
              title: Text('Luna'),
              subtitle: Text('Mascota · Perro · Sin cuenta de usuario'),
            ),
          ),
        ),
        const SectionHeader(title: 'Invitar familiar'),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pide a la persona su ID para invitaciones y pégalo aquí.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: Space.sm),
                TextField(
                  controller: inviteId,
                  maxLength: 32,
                  style: moneyStyle(text.bodyLarge),
                  decoration: const InputDecoration(
                    labelText: 'ID único del usuario',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  onChanged: (_) {
                    if (inviteError != null) {
                      setState(() => inviteError = null);
                    }
                  },
                  onSubmitted: (_) => _invite(),
                ),
                InlineMessage(text: inviteError, tone: Tone.warning),
                const SizedBox(height: Space.xs),
                FilledButton.icon(
                  onPressed: _invite,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar invitación'),
                ),
                for (final id in family.sent) ...[
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      const Icon(Icons.schedule_send_outlined, size: 20),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: moneyStyle(text.bodySmall),
                        ),
                      ),
                      const StatusBadge(label: 'Pendiente', tone: Tone.warning),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentsPreview extends StatelessWidget {
  const _DocumentsPreview();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.xxl,
      ),
      children: [
        const PageHeader(
          eyebrow: 'Documentos',
          title: 'El archivo de la familia',
          subtitle: 'Carpetas a tu manera, compartidas con intención.',
        ),
        const SectionHeader(title: 'Carpetas'),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - Space.sm) / 2;
            return Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final (i, folder) in const [
                  ('Identidad y registro', Icons.badge_outlined, Tone.info),
                  (
                    'Salud y vacunas',
                    Icons.health_and_safety_outlined,
                    Tone.success,
                  ),
                  ('Vida familiar', Icons.favorite_outline, Tone.danger),
                  (
                    'Trabajo y seguridad social',
                    Icons.work_outline,
                    Tone.warning,
                  ),
                ].indexed)
                  SizedBox(
                    width: width,
                    child: FadeSlideIn(
                      index: i,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconTile(icon: folder.$2, tone: folder.$3),
                              const SizedBox(height: Space.sm),
                              Text(
                                folder.$1,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall,
                              ),
                              const SizedBox(height: Space.xxs),
                              Text(
                                'Sin archivos cargados',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
