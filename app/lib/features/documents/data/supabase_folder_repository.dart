import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/read_all.dart';
import '../domain/document_policy.dart';
import '../domain/folder_repository.dart';

class SupabaseFolderRepository implements FolderRepository {
  const SupabaseFolderRepository(this.client);
  final SupabaseClient client;

  FolderRecord _map(Map<String, dynamic> row) {
    final ownerUserId = row['owner_user_id'] as String?;
    final petId = row['pet_id'] as String?;
    return FolderRecord(
      id: row['id'] as String,
      familyId: row['family_id'] as String,
      name: row['name'] as String,
      version: row['version'] as int,
      ownerKind: petId != null ? FolderOwnerKind.pet : FolderOwnerKind.human,
      ownerUserId: ownerUserId,
      petId: petId,
    );
  }

  @override
  Future<List<FolderRecord>> list(String familyId) async {
    final rows = await readAll(
      (from, to) => client
          .from('folders')
          .select('id,family_id,name,version,owner_user_id,pet_id')
          .eq('family_id', familyId)
          .order('name')
          .order('id')
          .range(from, to),
    );
    return rows.map(_map).toList();
  }

  @override
  Future<FolderRecord> create(String familyId, FolderInput input) async {
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    final name = DocumentPolicy.folderName(input.name);
    final payload = <String, dynamic>{
      'family_id': familyId,
      'name': name,
      if (input.ownerKind == FolderOwnerKind.human)
        'owner_user_id': client.auth.currentUser!.id
      else
        'pet_id': input.petId,
    };
    final row = await client
        .from('folders')
        .insert(payload)
        .select('id,family_id,name,version,owner_user_id,pet_id')
        .single();
    return _map(row);
  }

  @override
  Future<FolderRecord> rename(FolderRecord folder, String name) async {
    final trimmed = DocumentPolicy.folderName(name);
    final row = await client
        .from('folders')
        .update({'name': trimmed, 'version': folder.version})
        .eq('id', folder.id)
        .eq('version', folder.version)
        .select('id,family_id,name,version,owner_user_id,pet_id')
        .maybeSingle();
    if (row == null) {
      throw StateError('version_conflict');
    }
    return _map(row);
  }

  @override
  Future<void> delete(FolderRecord folder) async {
    await client.rpc(
      'delete_folder',
      params: {'p_folder_id': folder.id, 'p_expected_version': folder.version},
    );
  }
}
