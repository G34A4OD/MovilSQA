import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/connected_app.dart';
import 'core/secure_session_storage.dart';
import 'core/supabase_config.dart';
import 'features/identity/data/supabase_auth_repository.dart';
import 'core/app_theme.dart';
import 'core/money.dart';
import 'demo/demo_data.dart';
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
    runApp(ConnectedNidoApp(auth: SupabaseAuthRepository(supabase.client)));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
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
  int section = 0;
  @override
  void dispose() {
    budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.cottage_outlined),
          SizedBox(width: 10),
          Text(
            'nido',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: CircleAvatar(
            backgroundColor: Color(0xffe3e8d9),
            child: Icon(Icons.person_outline),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xffffedce),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Text(
              'Demostración local · Datos ficticios en memoria',
              style: TextStyle(fontSize: 12, color: Color(0xff664719)),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: switch (section) {
                  1 => const _FamilyPreview(),
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
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: section,
      onDestinationSelected: (v) => setState(() => section = v),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Familia',
        ),
        NavigationDestination(
          key: Key('budget-tab'),
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Presupuesto',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Documentos',
        ),
      ],
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.budget, required this.onNavigate});
  final BudgetViewModel budget;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 6),
      Text(
        'Hola, familia',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      const Text('Lo importante, un poquito más cerca.'),
      const SizedBox(height: 24),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.forest,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.diversity_1_outlined,
              color: Color(0xffdce9bd),
              size: 38,
            ),
            const SizedBox(height: 20),
            Text(
              'Un lugar para\ncuidar lo nuestro.',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Personas, recuerdos y planes de cada mes.\nAsí imaginamos el hogar digital de tu familia.',
              style: TextStyle(color: Color(0xffe3eadf), height: 1.6),
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: () => onNavigate(1),
              child: const Text('Conocer la familia de ejemplo'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Tu hogar, organizado',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const Icon(Icons.people_outline),
          title: const Text('Casa Rivera'),
          subtitle: const Text('4 familiares y una mascota · vista de ejemplo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onNavigate(1),
        ),
      ),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Archivo familiar'),
          subtitle: const Text('Un espacio para cada documento'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onNavigate(3),
        ),
      ),
      ListenableBuilder(
        listenable: budget,
        builder: (context, _) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.savings_outlined),
            title: Text(
              'Balance ${budget.year} · ${formatCents(budget.summary.balance)}',
            ),
            subtitle: const Text('Explora y edita un presupuesto de prueba'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onNavigate(2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Esta base no guarda información al cerrar. El acceso con cuentas, los grupos y los archivos privados se incorporan en las historias del equipo.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    ],
  );
}

class _FamilyPreview extends StatelessWidget {
  const _FamilyPreview();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Casa Rivera', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      const Text('Cada persona tiene su lugar.'),
      const SizedBox(height: 20),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vínculos de ejemplo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Elena y Luis son pareja.\nSon madre y padre de Ana y Mateo.\nAna y Mateo son hermanos.',
                style: TextStyle(height: 1.8),
              ),
            ],
          ),
        ),
      ),
      for (final member in const [
        ('Elena Rivera', 'Madre · Administradora', 'ER'),
        ('Luis Rivera', 'Padre · Miembro', 'LR'),
        ('Ana Rivera', 'Hija · Miembro', 'AR'),
        ('Mateo Rivera', 'Hijo · Miembro', 'MR'),
      ])
        Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(member.$3)),
            title: Text(member.$1),
            subtitle: Text(member.$2),
          ),
        ),
      const SizedBox(height: 20),
      Text(
        'También son familia',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.pets_outlined),
          title: Text('Luna'),
          subtitle: Text('Mascota · Perro · Sin cuenta de usuario'),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Vista de ejemplo. Las invitaciones y la edición de tu familia estarán disponibles en la versión completa.',
      ),
    ],
  );
}

class _DocumentsPreview extends StatelessWidget {
  const _DocumentsPreview();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'El archivo de la familia',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text('Carpetas a tu manera, compartidas con intención.'),
      const SizedBox(height: 24),
      for (final folder in const [
        ('Identidad y registro', Icons.badge_outlined),
        ('Salud y vacunas', Icons.health_and_safety_outlined),
        ('Vida familiar', Icons.favorite_outline),
        ('Trabajo y seguridad social', Icons.work_outline),
      ])
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: Icon(folder.$2),
            title: Text(folder.$1),
            subtitle: const Text('Ejemplo de carpeta · Sin archivos cargados'),
          ),
        ),
      const SizedBox(height: 24),
      const Icon(Icons.lock_outline, size: 36),
      const SizedBox(height: 12),
      const Text(
        'Antes de guardar algo real',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Tu archivo familiar necesita un espacio privado y acceso con tu cuenta. Esta demostración todavía no permite subir documentos.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
