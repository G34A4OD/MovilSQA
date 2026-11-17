class BudgetSheetInput {
  const BudgetSheetInput(this.name);
  final String name;
  bool get isValid {
    final trimmed = name.trim();
    return trimmed.length >= 2 && trimmed.length <= 100;
  }
}

class BudgetSheetRecord {
  const BudgetSheetRecord({
    required this.id,
    required this.familyId,
    required this.ownerId,
    required this.name,
    required this.version,
  });
  final String id;
  final String familyId;
  final String ownerId;
  final String name;
  final int version;
}

abstract interface class BudgetSheetRepository {
  Future<List<BudgetSheetRecord>> list(String familyId);
  Future<BudgetSheetRecord> create(
    String familyId,
    BudgetSheetInput input,
    String requestId,
  );
  Future<BudgetSheetRecord> rename(BudgetSheetRecord sheet, String name);
  Future<void> delete(BudgetSheetRecord sheet, String confirmation);
}
