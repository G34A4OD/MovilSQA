import 'package:flutter/foundation.dart';
import '../domain/document_policy.dart';
import '../domain/folder_repository.dart';

class FolderViewModel extends ChangeNotifier {
  FolderViewModel(this.repository, this.familyId, {required this.isAdmin});
  final FolderRepository repository;
  final String familyId;
  final bool isAdmin;
  List<FolderRecord> items = [];
  bool busy = false;
  bool _disposed = false;
  String? message;

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
    } on FormatException {
      message =
          'Usa un nombre de 1 a 100 caracteres, sin rutas, y un titular autorizado.';
      return false;
    } catch (_) {
      message =
          'No se completó. Revisa tu membresía, el titular y si la carpeta cambió en otro dispositivo.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() async {
    await _run(() async {});
  }

  Future<bool> create(FolderInput input) => _run(() async {
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    if (input.ownerKind == FolderOwnerKind.pet && !isAdmin) {
      throw const FormatException('forbidden');
    }
    DocumentPolicy.folderName(input.name);
    await repository.create(familyId, input);
  });

  Future<bool> rename(FolderRecord folder, String name) => _run(() async {
    DocumentPolicy.folderName(name);
    await repository.rename(folder, name);
  });

  Future<bool> delete(FolderRecord folder) =>
      _run(() => repository.delete(folder));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
