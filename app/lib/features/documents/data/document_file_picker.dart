import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/document_policy.dart';

/// Resultado de selección listo para el diálogo de carga.
typedef PickedDocumentBytes = ({String filename, Uint8List bytes});

/// Valida nombre/bytes ya leídos (sin I/O). Usado por el picker y por tests.
PickedDocumentBytes prepareDocumentPick({
  required String? filename,
  required Uint8List? bytes,
}) {
  final name = filename?.trim() ?? '';
  if (name.isEmpty || bytes == null) {
    throw const FormatException('Adjunta un archivo JPG, PNG o PDF.');
  }
  final lower = name.toLowerCase();
  if (!(lower.endsWith('.pdf') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png'))) {
    throw const FormatException('Selecciona una foto JPG/PNG o un PDF válido.');
  }
  if (bytes.isEmpty || bytes.length > DocumentPolicy.maxBytes) {
    throw const FormatException(
      'El archivo debe ocupar entre 1 byte y 10 MiB.',
    );
  }
  DocumentPolicy.detect(bytes, name);
  return (filename: name, bytes: bytes);
}

/// Selector real autorizado (file_picker). Cancelar devuelve null sin reservar.
Future<PickedDocumentBytes?> pickDocumentBytesWithFilePicker() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
  );
  if (file == null) {
    return null;
  }
  final knownLength = await file.length();
  if (knownLength != null &&
      (knownLength < 1 || knownLength > DocumentPolicy.maxBytes)) {
    throw const FormatException(
      'El archivo debe ocupar entre 1 byte y 10 MiB.',
    );
  }
  final bytes = await file.readAsBytes();
  return prepareDocumentPick(filename: file.name, bytes: bytes);
}
