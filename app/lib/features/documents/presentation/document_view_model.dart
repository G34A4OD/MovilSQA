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
      items = await repository.listQuarantine(folderId);
      return true;
    } on FormatException catch (error) {
      message = error.message;
      return false;
    } catch (_) {
      message =
          'No se completó la carga. Revisa membresía, titularidad, tamaño y tipo.';
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
