import 'document_policy.dart';

enum FolderOwnerKind { human, pet }

class FolderInput {
  const FolderInput({
    required this.name,
    required this.ownerKind,
    this.petId,
  });
  final String name;
  final FolderOwnerKind ownerKind;
  final String? petId;

  bool get isValid {
    try {
      DocumentPolicy.folderName(name);
    } on FormatException {
      return false;
    }
    return ownerKind == FolderOwnerKind.human
        ? petId == null
        : petId != null && petId!.trim().isNotEmpty;
  }
}

class FolderRecord {
  const FolderRecord({
    required this.id,
    required this.familyId,
    required this.name,
    required this.version,
    required this.ownerKind,
    this.ownerUserId,
    this.petId,
  });
  final String id;
  final String familyId;
  final String name;
  final int version;
  final FolderOwnerKind ownerKind;
  final String? ownerUserId;
  final String? petId;
}

abstract interface class FolderRepository {
  Future<List<FolderRecord>> list(String familyId);
  Future<FolderRecord> create(String familyId, FolderInput input);
  Future<FolderRecord> rename(FolderRecord folder, String name);
  Future<void> delete(FolderRecord folder);
}
