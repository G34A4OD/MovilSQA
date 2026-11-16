import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi Nido'),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión en este dispositivo',
          onPressed: widget.auth.busy ? null : widget.auth.signOut,
          icon: const Icon(Icons.logout),
        ),
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
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(model.message ?? 'Carga tu perfil'),
                        TextButton(
                          onPressed: model.load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
            );
          }
          if (editing || model.profile == null) {
            return Column(
              children: [
                if (model.profile != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => editing = false),
                      child: const Text('Volver'),
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
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Hola, ${p.details.fullName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tu ID para invitaciones'),
                      const SizedBox(height: 8),
                      SelectableText(p.publicId),
                      const SizedBox(height: 8),
                      const Text(
                        'Comparte este ID con el administrador de tu familia.',
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => editing = true),
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Editar mi perfil privado'),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.auth.message != null) Text(widget.auth.message!),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.diversity_1_outlined),
                label: const Text('Mis familias'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FamilyPage(
                      repository: widget.families,
                      profiles: widget.repository,
                      reauthenticate: (password) => widget.auth.repository
                          .signIn(widget.auth.session!.email, password),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
