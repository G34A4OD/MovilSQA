import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/read_all.dart';
import '../domain/family_repository.dart';
import '../domain/invitation_repository.dart';
import 'supabase_invitation_repository.dart';

class SupabaseFamilyRepository implements FamilyRepository {
  const SupabaseFamilyRepository(this.client);
  final SupabaseClient client;
  @override
  String? get currentUserId => client.auth.currentUser?.id;
  Future<void> _membership(
    String operation,
    Map<String, dynamic> params,
  ) async {
    try {
      await client.rpc(operation, params: params);
    } on PostgrestException catch (e) {
      throw FamilyFailure(
        e.message == 'last_admin' ? 'last_admin' : 'forbidden',
      );
    }
  }

  @override
  Future<void> setAdmin(String familyId, String targetUserId, bool value) =>
      _membership('set_member_admin', {
        'p_family_id': familyId,
        'p_target_user_id': targetUserId,
        'p_is_admin': value,
      });
  @override
  Future<void> leave(String familyId) =>
      _membership('leave_family', {'p_family_id': familyId});
  @override
  Future<void> remove(String familyId, String targetUserId) => _membership(
    'remove_member',
    {'p_family_id': familyId, 'p_target_user_id': targetUserId},
  );
  @override
  InvitationRepository get invitations => SupabaseInvitationRepository(client);
  @override
  Future<List<FamilyRecord>> list() async {
    final actor = client.auth.currentUser?.id;
    if (actor == null) throw StateError('forbidden');
    final rows = await readAll(
      (from, to) => client
          .from('memberships')
          .select('is_admin,families!inner(id,name,version)')
          .eq('user_id', actor)
          .eq('active', true)
          .order('family_id')
          .range(from, to),
    );
    return rows.map((r) {
      final f = r['families'] as Map<String, dynamic>;
      return FamilyRecord(
        id: f['id'] as String,
        name: f['name'] as String,
        version: f['version'] as int,
        isAdmin: r['is_admin'] as bool,
      );
    }).toList();
  }

  @override
  Future<List<FamilyMember>> members(String familyId) async {
    final rows = await readAll(
      (from, to) => client
          .from('memberships')
          .select('user_id,is_admin,profiles!inner(full_name,public_id)')
          .eq('family_id', familyId)
          .eq('active', true)
          .order('user_id')
          .range(from, to),
    );
    return rows.map((r) {
      final p = r['profiles'] as Map<String, dynamic>;
      return FamilyMember(
        userId: r['user_id'] as String,
        fullName: p['full_name'] as String,
        publicId: p['public_id'] as String,
        isAdmin: r['is_admin'] as bool,
      );
    }).toList();
  }

  @override
  Future<void> create(String name, String requestId) async {
    await client.rpc(
      'create_family',
      params: {'p_name': name.trim(), 'p_request_id': requestId},
    );
  }

  @override
  Future<void> update(FamilyRecord family, String name) async {
    await client.rpc(
      'update_family',
      params: {
        'p_family_id': family.id,
        'p_name': name.trim(),
        'p_expected_version': family.version,
      },
    );
  }

  @override
  Future<void> delete(FamilyRecord family, String confirmation) async {
    await client.rpc(
      'delete_family',
      params: {
        'p_family_id': family.id,
        'p_expected_version': family.version,
        'p_confirmation': confirmation,
      },
    );
  }
}
