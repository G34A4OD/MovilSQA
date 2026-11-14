import '../features/budget/domain/budget.dart';
import '../features/budget/presentation/budget_view_model.dart';

BudgetViewModel createDemoBudget() {
  final ledger = BudgetLedger(
    id: 'demo-sheet',
    familyId: 'demo-family',
    ownerId: 'demo-person',
  );
  for (final category in const [
    BudgetCategory(id: 'salary', name: 'Sueldo', kind: EntryKind.income),
    BudgetCategory(id: 'food', name: 'Alimentación', kind: EntryKind.expense),
    BudgetCategory(id: 'home', name: 'Hogar', kind: EntryKind.expense),
  ]) {
    ledger.saveCategory(category);
  }
  for (final entry in const [
    BudgetEntry(
      id: 'sample1',
      categoryId: 'salary',
      year: 2026,
      month: 11,
      amountCents: 450000,
      description: 'Ingreso de ejemplo',
    ),
    BudgetEntry(
      id: 'sample2',
      categoryId: 'food',
      year: 2026,
      month: 11,
      amountCents: 85000,
      description: 'Compras de ejemplo',
    ),
    BudgetEntry(
      id: 'sample3',
      categoryId: 'home',
      year: 2026,
      month: 11,
      amountCents: 130000,
      description: 'Servicios de ejemplo',
    ),
  ]) {
    ledger.saveEntry(entry);
  }
  return BudgetViewModel(ledger);
}
