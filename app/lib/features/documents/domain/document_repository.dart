import 'dart:typed_data';
import 'document_policy.dart';

enum DocumentStatus { quarantine, approved, rejected }

class DocumentUploadInput {
  const DocumentUploadInput({
    required this.title,
    required this.description,
    required this.filename,
    required this.bytes,
    this.expiresOn,
  });
  final String title;
  final String description;
  final String filename;
  final Uint8List bytes;
  final DateTime? expiresOn;

  bool get isValid {
    try {
      DocumentPolicy.title(title);
      DocumentPolicy.description(description);
      DocumentPolicy.expiresOn(expiresOn);
      DocumentPolicy.detect(bytes, filename);
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
}

class DocumentUploadReservation {
  const DocumentUploadReservation({
    required this.document,
    required this.storagePath,
  });
  final DocumentRecord document;
  final String storagePath;
}

abstract class DocumentRepository {
  Future<List<DocumentRecord>> listQuarantine(String folderId);
  Future<DocumentRecord> upload(String folderId, DocumentUploadInput input);
}
