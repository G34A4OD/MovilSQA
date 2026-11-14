import 'package:app/features/budget/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BudgetLedger ledger;
  setUp(() {
    ledger = BudgetLedger(
      id: 'sheet-a',
      familyId: 'family-a',
      ownerId: 'alice',
    );
    ledger.saveCategory(
      const BudgetCategory(
        id: 'salary',
        name: 'Sueldo',
        kind: EntryKind.income,
      ),
    );
    ledger.saveCategory(
      const BudgetCategory(
        id: 'food',
        name: 'Alimentación',
        kind: EntryKind.expense,
      ),
    );
  });
  BudgetEntry entry({
    String id = 'e1',
    int year = 2026,
    int month = 1,
    int cents = 100,
    String category = 'salary',
    String description = '',
  }) => BudgetEntry(
    id: id,
    categoryId: category,
    year: year,
    month: month,
    amountCents: cents,
    description: description,
  );

  test('TC-BUD-02 HU-14 suma mensual/anual y separa años', () {
    ledger.saveEntry(entry(cents: 15000));
    ledger.saveEntry(entry(id: 'e2', category: 'food', cents: 17500));
    ledger.saveEntry(entry(id: 'e3', year: 2025, cents: 900000));
    ledger.saveEntry(entry(id: 'e4', month: 12, cents: 3000));
    expect(ledger.monthSummary(2026, 1).balance, -2500);
    expect(ledger.yearSummary(2026).income, 18000);
    expect(ledger.yearSummary(2026).balance, 500);
    expect(ledger.monthSummary(2026, 2).balance, 0);
  });
  test('TC-BUD-02 HU-13 editar y eliminar recalcula sin duplicados', () {
    ledger.saveEntry(entry());
    ledger.saveEntry(entry(cents: 200));
    expect(ledger.entries.length, 1);
    expect(ledger.yearSummary(2026).balance, 200);
    ledger.deleteEntry('e1');
    expect(ledger.yearSummary(2026).balance, 0);
  });
  test('TC-BUD-03 HU-12 categoría usada no cambia tipo ni se elimina', () {
    ledger.saveEntry(entry());
    expect(() => ledger.deleteCategory('salary'), throwsStateError);
    expect(
      () => ledger.saveCategory(
        const BudgetCategory(
          id: 'salary',
          name: 'Otro',
          kind: EntryKind.expense,
        ),
      ),
      throwsStateError,
    );
    ledger.saveCategory(
      const BudgetCategory(
        id: 'salary',
        name: 'Nuevo sueldo',
        kind: EntryKind.income,
      ),
    );
    expect(ledger.categories.first.name, 'Nuevo sueldo');
  });
  test('TC-BUD-01 HU-13 límites de mes/año/monto y categoría ajena', () {
    for (final bad in [
      entry(month: 0),
      entry(month: 13),
      entry(year: 0),
      entry(year: 10000),
      entry(cents: 0),
      entry(cents: -1),
      entry(cents: 100000000000),
      entry(category: 'other-sheet'),
    ]) {
      expect(() => ledger.saveEntry(bad), throwsArgumentError);
    }
    ledger.saveEntry(entry(year: 1));
    ledger.saveEntry(entry(id: 'future', year: 9999, month: 12));
    expect(ledger.entries.length, 2);
  });
  test(
    'TC-BUD-04 HU-15 CSV con doce meses, totales y fórmulas neutralizadas',
    () {
      ledger.saveEntry(entry(description: '=HYPERLINK("bad")\ntexto,extra'));
      final csv = ledger.exportYearCsv(2026);
      expect(csv, contains("'=HYPERLINK"));
      expect(csv, contains('""bad""'));
      expect(csv, contains('2026,12,RESUMEN'));
      expect(csv, contains('TOTAL_ANUAL'));
      expect(csv, contains('1.00'));
      expect(csv, isNot(contains('other-sheet')));
      for (final attack in ['+SUM(1)', '-1+2', '@SUM(1)', ' \t=1', '\r=1']) {
        expect(csvCell(attack), contains("'"));
      }
    },
  );
  test('TC-BUD-03 HU-12 nombre de categoría vacío rechazado', () {
    expect(
      () => ledger.saveCategory(
        const BudgetCategory(id: 'empty', name: ' ', kind: EntryKind.income),
      ),
      throwsArgumentError,
    );
  });
}
