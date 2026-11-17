import 'dart:typed_data';
import 'document_policy.dart';

enum DocumentStatus { quarantine, approved, rejected }

/// Categorías orientativas HU-10.
enum DocumentCategory {
  identityCivic('identity_civic'),
  civilLife('civil_life'),
  socialLaborTax('social_labor_tax'),
  health('health');

  const DocumentCategory(this.code);
  final String code;

  static DocumentCategory fromCode(String? value) => switch (value) {
    'civil_life' => DocumentCategory.civilLife,
    'social_labor_tax' => DocumentCategory.socialLaborTax,
    'health' => DocumentCategory.health,
    _ => DocumentCategory.identityCivic,
  };
}

enum HealthNoteKind {
  allergy('allergy'),
  consultation('consultation'),
  prescription('prescription'),
  vaccine('vaccine');

  const HealthNoteKind(this.code);
  final String code;

  static HealthNoteKind? fromCode(String? value) => switch (value) {
    'allergy' => HealthNoteKind.allergy,
    'consultation' => HealthNoteKind.consultation,
    'prescription' => HealthNoteKind.prescription,
    'vaccine' => HealthNoteKind.vaccine,
    _ => null,
  };
}

class DocumentUploadInput {
  const DocumentUploadInput({
    required this.title,
    required this.description,
    required this.filename,
    required this.bytes,
    this.expiresOn,
    this.replacesDocumentId,
    this.category = DocumentCategory.identityCivic,
    this.healthNoteKind,
  });
  final String title;
  final String description;
  final String filename;
  final Uint8List bytes;
  final DateTime? expiresOn;
  final String? replacesDocumentId;
  final DocumentCategory category;
  final HealthNoteKind? healthNoteKind;

  bool get isValid {
    try {
      DocumentPolicy.title(title);
      DocumentPolicy.description(description);
      DocumentPolicy.expiresOn(expiresOn);
      DocumentPolicy.detect(bytes, filename);
      // Salud admite documento general (healthNoteKind null) o nota específica.
      if (category != DocumentCategory.health && healthNoteKind != null) {
        return false;
      }
      return true;
    } on FormatException {
      return false;
    }
  }

  String get mimeType => DocumentPolicy.detect(bytes, filename);
}

class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.folderId,
    required this.familyId,
    required this.title,
    required this.description,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    required this.storagePath,
    required this.version,
    this.expiresOn,
    this.publishedPath,
    this.category = DocumentCategory.identityCivic,
    this.healthNoteKind,
    this.uploadedBy,
    this.createdAt,
  });
  final String id;
  final String folderId;
  final String familyId;
  final String title;
  final String description;
  final String mimeType;
  final int sizeBytes;
  final DocumentStatus status;
  final String storagePath;
  final int version;
  final DateTime? expiresOn;
  final String? publishedPath;
  final DocumentCategory category;
  final HealthNoteKind? healthNoteKind;
  final String? uploadedBy;
  final DateTime? createdAt;
}

class DocumentProcessResult {
  const DocumentProcessResult({
    required this.status,
    this.error,
    this.idempotent = false,
  });
  final DocumentStatus status;
  final String? error;
  final bool idempotent;
}

class DocumentDownload {
  const DocumentDownload({
    required this.documentId,
    required this.mimeType,
    required this.bytes,
  });
  final String documentId;
  final String mimeType;
  final Uint8List bytes;
}

abstract class DocumentRepository {
  Future<List<DocumentRecord>> listByFolder(String folderId);
  Future<DocumentRecord> upload(String folderId, DocumentUploadInput input);
  Future<DocumentProcessResult> process(String documentId);
  Future<DocumentRecord> updateMetadata({
    required String documentId,
    required String title,
    required String description,
    required int expectedVersion,
    DateTime? expiresOn,
    DocumentCategory? category,
    HealthNoteKind? healthNoteKind,
  });
  Future<void> delete(String documentId, int expectedVersion);
  Future<DocumentDownload> download(String documentId);
}
