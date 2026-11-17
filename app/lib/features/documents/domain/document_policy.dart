import 'dart:typed_data';

/// Client-side early feedback only. A valid header does NOT prove a safe file.
/// The server must validate full content and quarantine/scan every upload.
abstract final class DocumentPolicy {
  static const maxBytes = 10 * 1024 * 1024;

  static String detect(Uint8List bytes, String filename) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException(
        'El archivo debe ocupar entre 1 byte y 10 MiB.',
      );
    }
    final lower = filename.toLowerCase();
    bool starts(List<int> signature) =>
        bytes.length >= signature.length &&
        signature.asMap().entries.every(
          (entry) => bytes[entry.key] == entry.value,
        );
    if (lower.endsWith('.pdf') && starts([37, 80, 68, 70, 45])) {
      return 'application/pdf';
    }
    if ((lower.endsWith('.jpg') || lower.endsWith('.jpeg')) &&
        starts([255, 216, 255])) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png') && starts([137, 80, 78, 71, 13, 10, 26, 10])) {
      return 'image/png';
    }
    throw const FormatException('Selecciona una foto JPG/PNG o un PDF válido.');
  }

  static String folderName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 100 ||
        trimmed.contains(RegExp(r'[/\\\x00-\x1f]'))) {
      throw const FormatException(
        'Usa un nombre de 1 a 100 caracteres, sin rutas.',
      );
    }
    return trimmed;
  }

  static String title(String value) => folderName(value);

  static String description(String value) {
    if (value.length > 1000) {
      throw const FormatException(
        'La descripción admite hasta 1000 caracteres.',
      );
    }
    return value;
  }

  static DateTime? expiresOn(DateTime? value, {DateTime? today}) {
    if (value == null) {
      return null;
    }
    final day = DateTime(value.year, value.month, value.day);
    final floor = today == null
        ? DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          )
        : DateTime(today.year, today.month, today.day);
    if (day.isBefore(floor)) {
      throw const FormatException(
        'El vencimiento opcional no puede ser una fecha pasada.',
      );
    }
    return day;
  }
}
