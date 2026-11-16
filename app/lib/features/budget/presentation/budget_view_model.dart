import 'package:flutter/foundation.dart';
import '../domain/budget.dart';

/// In-memory demo only; the production repository is a separate backlog item.
class BudgetViewModel extends ChangeNotifier {
  BudgetViewModel(this.ledger);
  final BudgetLedger ledger;
  int year = 2026;
  int month = 11;
  int _sequence = 100;
  String newId() => 'demo-${++_sequence}';
  BudgetSummary get summary => ledger.yearSummary(year);
  List<BudgetEntry> get currentEntries =>
      ledger.entries.where((e) => e.year == year && e.month == month).toList();
  void setYear(int value) {
    if (value < 1 || value > 9999) throw ArgumentError('Año entre 1 y 9999.');
    year = value;
    notifyListeners();
  }

  void setMonth(int value) {
    if (value < 1 || value > 12) throw ArgumentError('Mes inválido.');
    month = value;
    notifyListeners();
  }

  void saveEntry(BudgetEntry value) {
    ledger.saveEntry(value);
    notifyListeners();
  }

  void deleteEntry(String id) {
    ledger.deleteEntry(id);
    notifyListeners();
  }

  void saveCategory(BudgetCategory value) {
    ledger.saveCategory(value);
    notifyListeners();
  }

  void deleteCategory(String id) {
    ledger.deleteCategory(id);
    notifyListeners();
  }
}
