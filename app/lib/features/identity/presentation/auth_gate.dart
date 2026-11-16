import 'package:flutter/material.dart';
import 'auth_view_model.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.model,
    required this.signedInBuilder,
  });
  final AuthViewModel model;
  final Widget Function(BuildContext, AuthViewModel) signedInBuilder;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final secret = password.text;
    password.clear();
    if (widget.model.recovery) {
      await widget.model.savePassword(secret);
    } else {
      await widget.model.submit(email.text, secret);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model;
      if (m.session != null && !m.recovery) {
        return widget.signedInBuilder(context, m);
      }
      final title = m.recovery
          ? 'Nueva contraseña'
          : switch (m.mode) {
              AuthMode.signIn => 'Bienvenido a tu Nido',
              AuthMode.register => 'Crea tu cuenta',
              AuthMode.recover => 'Recupera tu acceso',
            };
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.cottage_outlined, size: 64),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('Un lugar para cuidar lo nuestro.'),
                      const SizedBox(height: 28),
                      if (!m.recovery)
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                          ),
                          enabled: !m.busy,
                        ),
                      if (m.recovery || m.mode != AuthMode.recover) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: password,
                          obscureText: hidden,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: [
                            m.mode == AuthMode.signIn && !m.recovery
                                ? AutofillHints.password
                                : AutofillHints.newPassword,
                          ],
                          onSubmitted: (_) {
                            if (!m.busy) submit();
                          },
                          enabled: !m.busy,
                          decoration: InputDecoration(
                            labelText: m.recovery
                                ? 'Nueva contraseña (mínimo 12 caracteres)'
                                : 'Contraseña',
                            suffixIcon: IconButton(
                              tooltip: hidden
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () => setState(() => hidden = !hidden),
                              icon: Icon(
                                hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (m.message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            m.message!,
                            semanticsLabel: m.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: m.busy ? null : submit,
                        child: Text(
                          m.busy
                              ? 'Un momento…'
                              : m.recovery
                              ? 'Guardar contraseña'
                              : switch (m.mode) {
                                  AuthMode.signIn => 'Entrar',
                                  AuthMode.register => 'Crear cuenta',
                                  AuthMode.recover => 'Enviar instrucciones',
                                },
                        ),
                      ),
                      if (!m.recovery) ...[
                        TextButton(
                          onPressed: m.busy
                              ? null
                              : () {
                                  password.clear();
                                  m.changeMode(
                                    m.mode == AuthMode.register
                                        ? AuthMode.signIn
                                        : AuthMode.register,
                                  );
                                },
                          child: Text(
                            m.mode == AuthMode.register
                                ? 'Ya tengo cuenta'
                                : 'Crear una cuenta',
                          ),
                        ),
                        TextButton(
                          onPressed: m.busy
                              ? null
                              : () {
                                  password.clear();
                                  m.changeMode(
                                    m.mode == AuthMode.recover
                                        ? AuthMode.signIn
                                        : AuthMode.recover,
                                  );
                                },
                          child: Text(
                            m.mode == AuthMode.recover
                                ? 'Volver al acceso'
                                : 'Olvidé mi contraseña',
                          ),
                        ),
                      ] else
                        TextButton(
                          onPressed: m.busy ? null : m.signOut,
                          child: const Text('Cancelar y cerrar sesión'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
