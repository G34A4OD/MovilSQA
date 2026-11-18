import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/sheet_repository.dart';

class SheetViewModel extends ChangeNotifier {
  SheetViewModel(this.repository, this.familyId);
  final BudgetSheetRepository repository;
  final String familyId;
  List<BudgetSheetRecord> items = [];
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
    } on FormatException {
      message = 'El nombre de la hoja necesita entre 2 y 100 caracteres.';
      return false;
    } catch (_) {
      message =
          'No se completó. Revisa que sigas en el grupo y que la hoja no haya cambiado.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() => _run(() async {});

  Future<bool> create(String name) => _run(() async {
    final input = BudgetSheetInput(name);
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    final key = 'sheet:$familyId:${input.name.trim()}';
    await repository.create(
      familyId,
      input,
      _requests.putIfAbsent(key, () => const Uuid().v4()),
    );
    _requests.remove(key);
  });

  Future<bool> rename(BudgetSheetRecord sheet, String name) => _run(() async {
    await repository.rename(sheet, name);
  });

  Future<bool> delete(BudgetSheetRecord sheet, String confirmation) =>
      _run(() async {
        await repository.delete(sheet, confirmation);
      });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
