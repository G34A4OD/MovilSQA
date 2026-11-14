import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/read_all.dart';
import '../domain/relationship_repository.dart';

class SupabaseRelationshipRepository implements RelationshipRepository {
  const SupabaseRelationshipRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<RelationshipRecord>> list(String familyId) async {
    final rows = await readAll(
      (from, to) => client
          .from('relationships')
          .select('id,from_user_id,to_user_id,kind,version')
          .eq('family_id', familyId)
          .order('created_at')
          .order('id')
          .range(from, to),
    );
    return rows
        .map(
          (r) => RelationshipRecord(
            id: r['id'] as String,
            fromUserId: r['from_user_id'] as String,
            toUserId: r['to_user_id'] as String,
            kind: r['kind'] as String,
            version: r['version'] as int,
          ),
        )
        .toList();
  }

  @override
  Future<void> save(
    String familyId,
    RelationshipInput input,
    String requestId, {
    RelationshipRecord? existing,
  }) async {
    await client.rpc(
      'save_relationship',
      params: {
        'p_family_id': familyId,
        'p_relationship_id': existing?.id,
        'p_from_user_id': input.fromUserId,
        'p_to_user_id': input.toUserId,
        'p_kind': input.role.kind,
        'p_expected_version': existing?.version,
        'p_request_id': requestId,
      },
    );
  }

  @override
  Future<void> delete(String familyId, RelationshipRecord relationship) async {
    await client.rpc(
      'delete_relationship',
      params: {
        'p_family_id': familyId,
        'p_relationship_id': relationship.id,
        'p_expected_version': relationship.version,
      },
    );
  }
}
