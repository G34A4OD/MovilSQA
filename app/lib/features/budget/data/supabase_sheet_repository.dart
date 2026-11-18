import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/read_all.dart';
import '../domain/sheet_repository.dart';

class SupabaseBudgetSheetRepository implements BudgetSheetRepository {
  const SupabaseBudgetSheetRepository(this.client);
  final SupabaseClient client;
  static const _columns = 'id,family_id,owner_id,name,version';

  BudgetSheetRecord _map(Map<String, dynamic> row) => BudgetSheetRecord(
    id: row['id'] as String,
    familyId: row['family_id'] as String,
    ownerId: row['owner_id'] as String,
    name: row['name'] as String,
    version: row['version'] as int,
  );

  @override
  Future<List<BudgetSheetRecord>> list(String familyId) async {
    final rows = await readAll(
      (from, to) => client
          .from('budget_sheets')
          .select(_columns)
          .eq('family_id', familyId)
          .order('name')
          .order('id')
          .range(from, to),
    );
    return rows.map(_map).toList();
  }

  @override
  Future<BudgetSheetRecord> create(
    String familyId,
    BudgetSheetInput input,
    String requestId,
  ) async {
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    final result = await client.rpc(
      'create_budget_sheet',
      params: {
        'p_family_id': familyId,
        'p_name': input.name.trim(),
        'p_request_id': requestId,
      },
    );
    return _map(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<BudgetSheetRecord> rename(BudgetSheetRecord sheet, String name) async {
    final input = BudgetSheetInput(name);
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    final result = await client.rpc(
      'update_budget_sheet',
      params: {
        'p_sheet_id': sheet.id,
        'p_name': input.name.trim(),
        'p_expected_version': sheet.version,
      },
    );
    return _map(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<void> delete(BudgetSheetRecord sheet, String confirmation) async {
    await client.rpc(
      'delete_budget_sheet',
      params: {
        'p_sheet_id': sheet.id,
        'p_expected_version': sheet.version,
        'p_confirmation': confirmation,
      },
    );
  }
}
