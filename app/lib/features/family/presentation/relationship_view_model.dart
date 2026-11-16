import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/relationship_repository.dart';

class RelationshipViewModel extends ChangeNotifier {
  RelationshipViewModel(this.repository, this.familyId);
  final RelationshipRepository repository;
  final String familyId;
  List<RelationshipRecord> items = [];
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
          'No se completó. Comprueba que ambos siguen en la familia, que no haya ciclos y que la versión siga vigente. Recarga antes de reintentar.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() async {
    await _run(() async {});
  }

  Future<bool> save(
    RelationshipInput input, {
    RelationshipRecord? existing,
  }) => _run(() async {
    if (input.personId == input.relativeId) {
      throw const FormatException('invalid_relationship');
    }
    final key =
        '${existing?.id}:${existing?.version}:${input.fromUserId}:${input.toUserId}:${input.role.kind}';
    await repository.save(
      familyId,
      input,
      _requests.putIfAbsent(key, () => const Uuid().v4()),
      existing: existing,
    );
    _requests.remove(key);
  });
  Future<bool> delete(RelationshipRecord item) =>
      _run(() => repository.delete(familyId, item));
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
