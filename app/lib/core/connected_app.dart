import 'package:flutter/material.dart';
import '../features/identity/domain/auth_repository.dart';
import '../features/identity/presentation/auth_gate.dart';
import '../features/identity/presentation/auth_view_model.dart';
import 'app_theme.dart';

class ConnectedNidoApp extends StatefulWidget {
  const ConnectedNidoApp({super.key, required this.auth});
  final AuthRepository auth;
  @override
  State<ConnectedNidoApp> createState() => _ConnectedNidoAppState();
}

class _ConnectedNidoAppState extends State<ConnectedNidoApp> {
  late final model = AuthViewModel(widget.auth);
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nido',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: AuthGate(
      model: model,
      signedInBuilder: (context, m) => Scaffold(
        appBar: AppBar(
          title: const Text('Mi Nido'),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión en este dispositivo',
              onPressed: m.busy ? null : m.signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu cuenta está conectada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(m.session!.email),
              const SizedBox(height: 20),
              const Text(
                'El perfil y tus grupos se habilitan con las siguientes historias.',
              ),
              if (m.message != null) Text(m.message!),
            ],
          ),
        ),
      ),
    ),
  );
}
