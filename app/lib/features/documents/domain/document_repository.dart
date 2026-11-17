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
    this.replacesDocumentId,
  });
  final String title;
  final String description;
  final String filename;
  final Uint8List bytes;
  final DateTime? expiresOn;
  final String? replacesDocumentId;

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
    this.publishedPath,
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
  });
  Future<void> delete(String documentId, int expectedVersion);
  Future<DocumentDownload> download(String documentId);
}
