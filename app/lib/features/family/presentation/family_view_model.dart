import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/family_repository.dart';

class FamilyViewModel extends ChangeNotifier {
  FamilyViewModel(this.repository);
  final FamilyRepository repository;
  List<FamilyRecord> families = [];
  List<FamilyMember> members = [];
  FamilyRecord? selected;
  bool busy = false;
  bool _disposed = false;
  String? message;
  String? _pendingName;
  String? _pendingId;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _refresh() async {
    families = await repository.list();
    final previous = selected?.id;
    selected = null;
    members = [];
    for (final f in families) {
      if (f.id == previous) selected = f;
    }
    if (selected != null) members = await repository.members(selected!.id);
  }

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    message = null;
    _notify();
    try {
      await action();
      await _refresh();
      return true;
    } on FamilyFailure catch (error) {
      message = error.code == 'last_admin'
          ? 'El grupo necesita al menos un administrador. Designa otro antes de renunciar o salir.'
          : 'Tu permiso cambió o la acción no está disponible. Recarga el grupo.';
      return false;
    } catch (_) {
      message =
          'No se completó la acción. Revisa conexión, permisos y cambios de otro dispositivo; recarga para actualizar.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() async {
    await run(() async {});
  }

  Future<void> select(FamilyRecord family) async {
    selected = family;
    members = [];
    await load();
  }

  Future<bool> create(String name) => run(() async {
    if (name.trim().length < 2 || name.trim().length > 100) {
      throw const FormatException('validation_error');
    }
    if (_pendingName != name.trim()) {
      _pendingName = name.trim();
      _pendingId = const Uuid().v4();
    }
    await repository.create(name, _pendingId!);
    _pendingId = null;
    _pendingName = null;
  });
  Future<bool> update(FamilyRecord family, String name) =>
      run(() => repository.update(family, name));
  Future<bool> delete(FamilyRecord family, String confirmation) =>
      run(() => repository.delete(family, confirmation));
  Future<bool> setAdmin(FamilyRecord family, FamilyMember member, bool value) =>
      run(() => repository.setAdmin(family.id, member.userId, value));
  Future<bool> leave(FamilyRecord family) =>
      run(() => repository.leave(family.id));
  Future<bool> remove(FamilyRecord family, FamilyMember member) =>
      run(() => repository.remove(family.id, member.userId));
  void back() {
    selected = null;
    members = [];
    message = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
