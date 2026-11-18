import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
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

  static Tone _tone(String message) {
    if (message.startsWith('Contraseña actualizada')) return Tone.success;
    if (message.startsWith('Revisa tu correo') ||
        message.startsWith('Si el correo')) {
      return Tone.info;
    }
    return Tone.danger;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model;
      if (m.session != null && !m.recovery) {
        return widget.signedInBuilder(context, m);
      }
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      final title = m.recovery
          ? 'Nueva contraseña'
          : switch (m.mode) {
              AuthMode.signIn => 'Bienvenido a tu Nido',
              AuthMode.register => 'Crea tu cuenta',
              AuthMode.recover => 'Recupera tu acceso',
            };
      final subtitle = m.recovery
          ? 'Elige una contraseña nueva para tu cuenta.'
          : switch (m.mode) {
              AuthMode.signIn => 'Un lugar para cuidar lo nuestro.',
              AuthMode.register =>
                'Tu archivo y presupuesto familiar, en un solo lugar.',
              AuthMode.recover =>
                'Te enviaremos instrucciones a tu correo electrónico.',
            };
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.6),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xl,
                    vertical: Space.xxl,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandMark(size: 64)),
                        const SizedBox(height: Space.xl),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: text.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Space.xl),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(Space.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!m.recovery)
                                  TextField(
                                    controller: email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: m.mode == AuthMode.recover
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    autocorrect: false,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                      labelText: 'Correo electrónico',
                                      prefixIcon: Icon(
                                        Icons.mail_outline_rounded,
                                      ),
                                    ),
                                    enabled: !m.busy,
                                  ),
                                AnimatedSize(
                                  duration: Motion.of(context, Motion.medium),
                                  curve: Motion.curve,
                                  alignment: Alignment.topCenter,
                                  child:
                                      m.recovery || m.mode != AuthMode.recover
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            top: m.recovery ? 0 : Space.md,
                                          ),
                                          child: TextField(
                                            controller: password,
                                            obscureText: hidden,
                                            enableSuggestions: false,
                                            autocorrect: false,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: [
                                              m.mode == AuthMode.signIn &&
                                                      !m.recovery
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
                                              helperText:
                                                  m.mode == AuthMode.register &&
                                                      !m.recovery
                                                  ? 'Entre 12 y 128 caracteres.'
                                                  : null,
                                              prefixIcon: const Icon(
                                                Icons.lock_outline_rounded,
                                              ),
                                              suffixIcon: IconButton(
                                                tooltip: hidden
                                                    ? 'Mostrar contraseña'
                                                    : 'Ocultar contraseña',
                                                onPressed: () => setState(
                                                  () => hidden = !hidden,
                                                ),
                                                icon: Icon(
                                                  hidden
                                                      ? Icons
                                                            .visibility_outlined
                                                      : Icons
                                                            .visibility_off_outlined,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(width: double.infinity),
                                ),
                                if (!m.recovery && m.mode == AuthMode.signIn)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: m.busy
                                          ? null
                                          : () {
                                              password.clear();
                                              m.changeMode(AuthMode.recover);
                                            },
                                      child: const Text('Olvidé mi contraseña'),
                                    ),
                                  )
                                else
                                  const SizedBox(height: Space.md),
                                InlineMessage(
                                  text: m.message,
                                  tone: m.message == null
                                      ? Tone.info
                                      : _tone(m.message!),
                                ),
                                const SizedBox(height: Space.xs),
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
                                            AuthMode.recover =>
                                              'Enviar instrucciones',
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        if (!m.recovery) ...[
                          if (m.mode != AuthMode.recover)
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  m.mode == AuthMode.register
                                      ? '¿Ya eres parte de Nido?'
                                      : '¿Primera vez aquí?',
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
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
                              ],
                            ),
                          if (m.mode != AuthMode.signIn)
                            TextButton.icon(
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
                              icon: Icon(
                                m.mode == AuthMode.recover
                                    ? Icons.arrow_back_rounded
                                    : Icons.key_outlined,
                                size: 18,
                              ),
                              label: Text(
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
                        const SizedBox(height: Space.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: Space.xs),
                            Flexible(
                              child: Text(
                                'Tus datos familiares son privados.',
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
