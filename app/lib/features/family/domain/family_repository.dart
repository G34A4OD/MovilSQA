import '../../documents/domain/document_repository.dart';
import '../../documents/domain/folder_repository.dart';
import 'invitation_repository.dart';
import 'relationship_repository.dart';
import 'pet_repository.dart';
import '../../budget/domain/sheet_repository.dart';

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
  String? get currentUserId;
  InvitationRepository get invitations;
  RelationshipRepository get relationships;
  PetRepository get pets;
  FolderRepository get folders;
  BudgetSheetRepository get sheets;
  DocumentRepository get documents;
  Future<void> setAdmin(String familyId, String targetUserId, bool value);
  Future<void> leave(String familyId);
  Future<void> remove(String familyId, String targetUserId);
  Future<List<FamilyRecord>> list();
  Future<List<FamilyMember>> members(String familyId);
  Future<void> create(String name, String requestId);
  Future<void> update(FamilyRecord family, String name);
  Future<void> delete(FamilyRecord family, String confirmation);
}

class FamilyFailure implements Exception {
  const FamilyFailure(this.code);
  final String code;
}
