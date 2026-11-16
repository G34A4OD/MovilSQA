import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/invitation_repository.dart';

class InvitationViewModel extends ChangeNotifier {
  InvitationViewModel(this.repository, {this.familyId});
  final InvitationRepository repository;
  final String? familyId;
  List<InvitationRecord> items = [];
  InvitationCandidate? candidate;
  bool busy = false;
  bool _disposed = false;
  String? message;
  final _requests = <String, String>{};
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _load() async {
    items = familyId == null
        ? await repository.received()
        : await repository.sent(familyId!);
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
      return true;
    } catch (_) {
      message =
          'No se completó. Puede haber caducado, cambiado tu permiso o alcanzado el límite de búsqueda. Recarga o espera un minuto.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() async {
    await _run(_load);
  }

  void clearCandidate() {
    candidate = null;
    message = null;
    _notify();
  }

  Future<void> lookup(String publicId) async {
    await _run(() async {
      candidate = null;
      if (familyId == null ||
          !RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(publicId.trim())) {
        message = 'Copia el ID completo de 32 caracteres de tu familiar.';
        return;
      }
      candidate = await repository.lookup(familyId!, publicId.trim());
      if (candidate == null) {
        message = 'No hay una coincidencia disponible.';
      }
    });
  }

  Future<bool> invite() => _run(() async {
    final selected = candidate;
    if (selected == null || familyId == null) {
      throw StateError('validation_error');
    }
    final key = 'invite:$familyId:${selected.publicId}';
    await repository.invite(
      familyId!,
      selected.publicId,
      _requests.putIfAbsent(key, () => const Uuid().v4()),
    );
    _requests.remove(key);
    candidate = null;
    await _load();
    message = 'Invitación enviada. Tu familiar debe aceptarla.';
  });
  Future<bool> respond(InvitationRecord item, String decision) =>
      _run(() async {
        final key = 'respond:${item.id}:$decision';
        await repository.respond(
          item.id,
          decision,
          _requests.putIfAbsent(key, () => const Uuid().v4()),
        );
        _requests.remove(key);
        await _load();
      });
  Future<bool> revoke(InvitationRecord item) => _run(() async {
    await repository.revoke(item.id);
    await _load();
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
