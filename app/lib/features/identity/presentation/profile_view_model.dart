import 'package:flutter/foundation.dart';
import '../domain/profile.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.repository);
  final ProfileRepository repository;
  PersonalProfile? profile;
  bool busy = false;
  bool loaded = false;
  bool _disposed = false;
  String? message;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      profile = await repository.load();
      loaded = true;
    } catch (_) {
      message =
          'No se pudo cargar tu perfil. Reintenta o vuelve a iniciar sesión.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> save(ProfileInput input) async {
    if (busy) return false;
    if (!input.isValid) {
      message = 'Revisa nombre, CI, domicilio y fecha (AAAA-MM-DD).';
      _notify();
      return false;
    }
    busy = true;
    message = null;
    _notify();
    try {
      profile = await repository.save(input, expectedVersion: profile?.version);
      return true;
    } catch (_) {
      message =
          'No se guardó el perfil. Si fue editado en otro dispositivo, recarga antes de reintentar.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
