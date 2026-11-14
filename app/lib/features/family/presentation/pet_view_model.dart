import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/pet_repository.dart';

class PetViewModel extends ChangeNotifier {
  PetViewModel(this.repository, this.familyId);
  final PetRepository repository;
  final String familyId;
  List<PetRecord> items = [];
  bool busy = false;
  bool _disposed = false;
  String? message;
  final _requests = <String, String>{};
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) {
      return false;
    }
    busy = true;
    message = null;
    _notify();
    try {
      await action();
      items = await repository.list(familyId);
      return true;
    } catch (_) {
      message =
          'No se completó. Revisa los datos, tu permiso de administrador y si la mascota fue editada en otro dispositivo. Recarga antes de reintentar.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() async {
    await _run(() async {});
  }

  Future<bool> save(PetInput input, {PetRecord? existing}) => _run(() async {
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    final key = jsonEncode({
      'id': existing?.id,
      'version': existing?.version,
      ...input.fields,
    });
    await repository.save(
      familyId,
      input,
      _requests.putIfAbsent(key, () => const Uuid().v4()),
      existing: existing,
    );
    _requests.remove(key);
  });
  Future<bool> delete(PetRecord pet) => _run(() => repository.delete(pet));
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
