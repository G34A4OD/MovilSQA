class InvitationRecord {
  const InvitationRecord({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.targetName,
    required this.status,
    required this.expiresAt,
  });
  final String id, familyId, familyName, targetName, status;
  final DateTime expiresAt;
  bool get actionable =>
      status == 'pending' && expiresAt.isAfter(DateTime.now());
  factory InvitationRecord.fromJson(Map<String, dynamic> r) => InvitationRecord(
    id: r['id'] as String,
    familyId: r['family_id'] as String,
    familyName: r['family_name'] as String,
    targetName: r['target_name'] as String,
    status: r['status'] as String,
    expiresAt: DateTime.parse(r['expires_at'] as String),
  );
}

class InvitationCandidate {
  const InvitationCandidate({required this.publicId, required this.fullName});
  final String publicId, fullName;
}

abstract interface class InvitationRepository {
  Future<List<InvitationRecord>> received();
  Future<List<InvitationRecord>> sent(String familyId);
  Future<InvitationCandidate?> lookup(String familyId, String publicId);
  Future<void> invite(String familyId, String publicId, String requestId);
  Future<void> respond(String invitationId, String decision, String requestId);
  Future<void> revoke(String invitationId);
}
