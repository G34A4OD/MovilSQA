import 'package:flutter/material.dart';
import '../features/identity/domain/auth_repository.dart';
import '../features/identity/presentation/auth_gate.dart';
import '../features/identity/presentation/auth_view_model.dart';
import '../features/identity/domain/profile.dart';
import '../features/identity/presentation/account_home.dart';
import 'app_theme.dart';
import '../features/family/domain/family_repository.dart';

class ConnectedNidoApp extends StatefulWidget {
  const ConnectedNidoApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.families,
  });
  final AuthRepository auth;
  final ProfileRepository profiles;
  final FamilyRepository families;
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => MaterialApp(
      key: ValueKey((model.session?.userId, model.recovery)),
      title: 'Nido',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: AuthGate(
        model: model,
        signedInBuilder: (context, m) => AccountHome(
          key: ValueKey(m.session!.userId),
          auth: m,
          repository: widget.profiles,
          families: widget.families,
        ),
      ),
    ),
  );
}
