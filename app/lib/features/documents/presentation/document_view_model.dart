import 'package:flutter/foundation.dart';
import '../domain/document_policy.dart';
import '../domain/document_repository.dart';

class DocumentViewModel extends ChangeNotifier {
  DocumentViewModel(this.repository, this.folderId);
  final DocumentRepository repository;
  final String folderId;
  List<DocumentRecord> items = [];
  bool busy = false;
  bool _disposed = false;
  String? message;
  DocumentDownload? lastDownload;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) {
      return false;
    }
    busy = true;
    message = null;
    _notify();
    try {
      await action();
      items = await repository.listByFolder(folderId);
      return true;
    } on FormatException catch (error) {
      message = error.message;
      return false;
    } catch (_) {
      message =
          'No se completó la operación. Revisa membresía, titularidad y versión.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() async {
    await _run(() async {});
  }

  Future<bool> upload(DocumentUploadInput input) => _run(() async {
    if (!input.isValid) {
      throw const FormatException(
        'Revisa título, descripción, vencimiento y el archivo JPG/PNG/PDF (máx. 10 MiB).',
      );
    }
    DocumentPolicy.title(input.title);
    DocumentPolicy.description(input.description);
    DocumentPolicy.expiresOn(input.expiresOn);
    DocumentPolicy.detect(input.bytes, input.filename);
    await repository.upload(folderId, input);
  });

  Future<bool> process(DocumentRecord document) => _run(() async {
    final result = await repository.process(document.id);
    if (result.status == DocumentStatus.quarantine &&
        result.error == 'scanner_unavailable') {
      message =
          'El archivo sigue en cuarentena: no hay escáner acordado/operativo.';
    } else if (result.status == DocumentStatus.rejected) {
      message = 'El archivo fue rechazado tras validar los bytes.';
    }
  });

  Future<bool> updateMetadata({
    required DocumentRecord document,
    required String title,
    required String description,
    DateTime? expiresOn,
  }) => _run(() async {
    await repository.updateMetadata(
      documentId: document.id,
      title: title,
      description: description,
      expectedVersion: document.version,
      expiresOn: expiresOn,
    );
  });

  Future<bool> delete(DocumentRecord document) => _run(() async {
    await repository.delete(document.id, document.version);
  });

  Future<bool> download(DocumentRecord document) => _run(() async {
    lastDownload = await repository.download(document.id);
    message =
        'Descarga lista (${lastDownload!.bytes.length} B). Copia local no se revoca.';
  });

  Future<bool> replace(
    DocumentRecord document,
    DocumentUploadInput input,
  ) => _run(() async {
    final replacement = DocumentUploadInput(
      title: input.title,
      description: input.description,
      filename: input.filename,
      bytes: input.bytes,
      expiresOn: input.expiresOn,
      replacesDocumentId: document.id,
    );
    if (!replacement.isValid) {
      throw const FormatException(
        'Revisa título, descripción, vencimiento y el archivo JPG/PNG/PDF (máx. 10 MiB).',
      );
    }
    await repository.upload(folderId, replacement);
  });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
