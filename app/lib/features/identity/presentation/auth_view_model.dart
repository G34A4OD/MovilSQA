import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/auth_repository.dart';

enum AuthMode { signIn, register, recover }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.repository) : session = repository.currentSession {
    _subscription = repository.sessions.listen(
      (value) {
        session = value;
        // Preserve recovery mode through token refresh, until password is changed.
        if (value == null) recovery = false;
        if (value?.recovery ?? false) recovery = true;
        message = null;
        _notify();
      },
      onError: (Object _) {
        message = 'No se pudo comprobar la sesión. Vuelve a intentarlo.';
        _notify();
      },
    );
  }
  final AuthRepository repository;
  late final StreamSubscription<IdentitySession?> _subscription;
  IdentitySession? session;
  AuthMode mode = AuthMode.signIn;
  bool busy = false;
  bool recovery = false;
  String? message;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void changeMode(AuthMode value) {
    mode = value;
    message = null;
    _notify();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await action();
    } catch (_) {
      message =
          'No se pudo completar. Revisa los datos, la conexión y vuelve a intentarlo.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> submit(String email, String password) => _run(() async {
    if (!validEmail(email) ||
        (mode != AuthMode.recover &&
            (password.isEmpty || password.length > 128))) {
      message = 'Escribe un correo válido y tu contraseña.';
      return;
    }
    switch (mode) {
      case AuthMode.signIn:
        await repository.signIn(email, password);
      case AuthMode.register:
        if (!validPassword(password)) {
          message = 'Usa una contraseña de 12 a 128 caracteres.';
          return;
        }
        await repository.register(email, password);
        message =
            'Revisa tu correo para confirmar tu cuenta. Si ya tienes cuenta, inicia sesión.';
      case AuthMode.recover:
        await repository.sendRecovery(email);
        message =
            'Si el correo corresponde a una cuenta, recibirás instrucciones para recuperar el acceso.';
    }
  });
  Future<void> savePassword(String password) => _run(() async {
    if (!validPassword(password)) {
      message = 'Usa una contraseña de 12 a 128 caracteres.';
      return;
    }
    await repository.updatePassword(password);
    recovery = false;
    message = 'Contraseña actualizada.';
  });
  Future<void> signOut() => _run(() async {
    await repository.signOut();
    session = null;
    recovery = false;
    mode = AuthMode.signIn;
  });
  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
