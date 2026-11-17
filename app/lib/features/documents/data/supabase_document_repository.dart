import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/read_all.dart';
import '../domain/document_policy.dart';
import '../domain/document_repository.dart';

class SupabaseDocumentRepository implements DocumentRepository {
  const SupabaseDocumentRepository(this.client);
  final SupabaseClient client;
  static const _uuid = Uuid();

  DocumentStatus _status(String value) => switch (value) {
    'approved' => DocumentStatus.approved,
    'rejected' => DocumentStatus.rejected,
    _ => DocumentStatus.quarantine,
  };

  DocumentRecord _map(Map<String, dynamic> row) {
    final expires = row['expires_on'];
    return DocumentRecord(
      id: row['id'] as String,
      folderId: row['folder_id'] as String,
      familyId: row['family_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      mimeType: row['declared_mime_type'] as String,
      sizeBytes: row['size_bytes'] as int,
      status: _status(row['status'] as String),
      storagePath: row['storage_path'] as String,
      version: row['version'] as int,
      expiresOn: expires == null ? null : DateTime.parse(expires as String),
    );
  }

  @override
  Future<List<DocumentRecord>> listQuarantine(String folderId) async {
    final rows = await readAll(
      (from, to) => client
          .from('documents')
          .select(
            'id,folder_id,family_id,title,description,declared_mime_type,'
            'size_bytes,status,storage_path,version,expires_on',
          )
          .eq('folder_id', folderId)
          .eq('status', 'quarantine')
          .order('created_at')
          .order('id')
          .range(from, to),
    );
    return rows.map(_map).toList();
  }

  @override
  Future<DocumentRecord> upload(
    String folderId,
    DocumentUploadInput input,
  ) async {
    if (!input.isValid) {
      throw const FormatException('validation_error');
    }
    final title = DocumentPolicy.title(input.title);
    final description = DocumentPolicy.description(input.description);
    final expires = DocumentPolicy.expiresOn(input.expiresOn);
    final mime = input.mimeType;
    final reserved = await client.rpc(
      'begin_document_upload',
      params: {
        'p_folder_id': folderId,
        'p_title': title,
        'p_description': description,
        'p_expires_on': expires?.toIso8601String().split('T').first,
        'p_filename': input.filename,
        'p_size_bytes': input.bytes.length,
        'p_request_id': _uuid.v4(),
      },
    );
    final row = Map<String, dynamic>.from(reserved as Map);
    final path = row['storage_path'] as String;
    try {
      await client.storage
          .from('nido-quarantine')
          .uploadBinary(
            path,
            input.bytes,
            fileOptions: FileOptions(upsert: false, contentType: mime),
          );
    } catch (_) {
      // Compensación completa (borrar metadata huérfana) queda para el
      // incremento de cuarentena/escaneo; la fila queda en quarantine sin bytes.
      rethrow;
    }
    return _map(row);
  }

  @override
  Future<DocumentProcessResult> process(String documentId) async {
    final session = client.auth.currentSession;
    if (session == null) {
      throw StateError('forbidden');
    }
    final response = await client.functions.invoke(
      'process-document',
      body: {'document_id': documentId},
    );
    final data = response.data;
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final status = switch (map['status'] as String?) {
      'approved' => DocumentStatus.approved,
      'rejected' => DocumentStatus.rejected,
      _ => DocumentStatus.quarantine,
    };
    if (response.status == 503 || map['error'] == 'scanner_unavailable') {
      return DocumentProcessResult(
        status: DocumentStatus.quarantine,
        error: 'scanner_unavailable',
        idempotent: map['idempotent'] == true,
      );
    }
    if (response.status >= 400 && status == DocumentStatus.quarantine) {
      throw StateError(map['error']?.toString() ?? 'process_failed');
    }
    return DocumentProcessResult(
      status: status,
      error: map['error'] as String?,
      idempotent: map['idempotent'] == true,
    );
  }
}
