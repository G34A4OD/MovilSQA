import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/read_all.dart';
import '../domain/invitation_repository.dart';

class SupabaseInvitationRepository implements InvitationRepository {
  const SupabaseInvitationRepository(this.client);
  final SupabaseClient client;
  static const columns =
      'id,family_id,family_name,target_name,status,expires_at';
  @override
  Future<List<InvitationRecord>> received() async {
    final actor = client.auth.currentUser?.id;
    if (actor == null) {
      throw StateError('forbidden');
    }
    final rows = await readAll(
      (from, to) => client
          .from('invitations')
          .select(columns)
          .eq('target_user_id', actor)
          .eq('status', 'pending')
          .order('created_at')
          .order('id')
          .range(from, to),
    );
    return rows.map(InvitationRecord.fromJson).toList();
  }

  @override
  Future<List<InvitationRecord>> sent(String familyId) async {
    final rows = await readAll(
      (from, to) => client
          .from('invitations')
          .select(columns)
          .eq('family_id', familyId)
          .eq('status', 'pending')
          .order('created_at')
          .order('id')
          .range(from, to),
    );
    return rows.map(InvitationRecord.fromJson).toList();
  }

  @override
  Future<InvitationCandidate?> lookup(String familyId, String publicId) async {
    final response = await client.functions.invoke(
      'lookup-user',
      body: {'family_id': familyId, 'public_id': publicId.trim().toLowerCase()},
    );
    final r = response.data;
    return r == null
        ? null
        : InvitationCandidate(
            publicId: r['public_id'] as String,
            fullName: r['full_name'] as String,
          );
  }

  @override
  Future<void> invite(
    String familyId,
    String publicId,
    String requestId,
  ) async {
    final result = await client.rpc(
      'invite_member',
      params: {
        'p_family_id': familyId,
        'p_target_public_id': publicId,
        'p_request_id': requestId,
      },
    );
    if (result is Map && result['error'] != null) {
      throw StateError(result['error'] as String);
    }
  }

  @override
  Future<void> respond(
    String invitationId,
    String decision,
    String requestId,
  ) async {
    await client.rpc(
      'respond_invitation',
      params: {
        'p_invitation_id': invitationId,
        'p_decision': decision,
        'p_request_id': requestId,
      },
    );
  }

  @override
  Future<void> revoke(String invitationId) async {
    await client.rpc(
      'revoke_invitation',
      params: {'p_invitation_id': invitationId},
    );
  }
}
