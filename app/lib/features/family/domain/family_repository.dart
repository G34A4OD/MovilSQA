class FamilyRecord {
  const FamilyRecord({
    required this.id,
    required this.name,
    required this.version,
    required this.isAdmin,
  });
  final String id;
  final String name;
  final int version;
  final bool isAdmin;
}

class FamilyMember {
  const FamilyMember({
    required this.userId,
    required this.fullName,
    required this.publicId,
    required this.isAdmin,
  });
  final String userId;
  final String fullName;
  final String publicId;
  final bool isAdmin;
}

abstract interface class FamilyRepository {
  Future<List<FamilyRecord>> list();
  Future<List<FamilyMember>> members(String familyId);
  Future<void> create(String name, String requestId);
  Future<void> update(FamilyRecord family, String name);
  Future<void> delete(FamilyRecord family, String confirmation);
}
