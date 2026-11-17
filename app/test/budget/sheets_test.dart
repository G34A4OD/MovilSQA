import 'package:app/features/budget/domain/sheet_repository.dart';
import 'package:app/features/budget/presentation/sheet_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSheets implements BudgetSheetRepository {
  List<BudgetSheetRecord> values = [];
  bool fail = false;

  @override
  Future<List<BudgetSheetRecord>> list(String familyId) async =>
      values.where((sheet) => sheet.familyId == familyId).toList();

  @override
  Future<BudgetSheetRecord> create(
    String familyId,
    BudgetSheetInput input,
    String requestId,
  ) async {
    if (!input.isValid || fail) {
      throw const FormatException('validation_error');
    }
    final record = BudgetSheetRecord(
      id: 'hoja-${values.length + 1}',
      familyId: familyId,
      ownerId: 'yo',
      name: input.name.trim(),
      version: 1,
    );
    values = [...values, record];
    return record;
  }

  @override
  Future<BudgetSheetRecord> rename(BudgetSheetRecord sheet, String name) async {
    final updated = BudgetSheetRecord(
      id: sheet.id,
      familyId: sheet.familyId,
      ownerId: sheet.ownerId,
      name: name.trim(),
      version: sheet.version + 1,
    );
    values = [
      for (final item in values)
        if (item.id == sheet.id) updated else item,
    ];
    return updated;
  }

  @override
  Future<void> delete(BudgetSheetRecord sheet, String confirmation) async {
    if (confirmation != sheet.name) {
      throw StateError('validation_error');
    }
    values = values.where((item) => item.id != sheet.id).toList();
  }
}

void main() {
  test(
    'TC-BUD-05 HU-11: el nombre de la hoja tiene entre 2 y 100 caracteres',
    () {
      expect(const BudgetSheetInput('Casa').isValid, isTrue);
      expect(const BudgetSheetInput(' ').isValid, isFalse);
    },
  );

  test(
    'TC-BUD-05 HU-11: crear dos hojas y no borrar con otro nombre',
    () async {
      final repository = FakeSheets();
      final model = SheetViewModel(repository, 'familia');
      expect(await model.create('Casa'), isTrue);
      expect(await model.create('Viaje'), isTrue);
      expect(model.items.map((sheet) => sheet.name), ['Casa', 'Viaje']);
      expect(await model.delete(model.items.first, 'Otra'), isFalse);
      expect(model.items, hasLength(2));
      expect(await model.delete(model.items.first, 'Casa'), isTrue);
      expect(model.items.single.name, 'Viaje');
      model.dispose();
    },
  );
}
