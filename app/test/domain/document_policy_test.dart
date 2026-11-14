import 'dart:typed_data';
import 'package:app/features/documents/domain/document_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-DOC-02 HU-09 valida firma y tamaño de PDF/JPG/PNG', () {
    expect(
      DocumentPolicy.detect(
        Uint8List.fromList([37, 80, 68, 70, 45, 49]),
        'report.pdf',
      ),
      'application/pdf',
    );
    expect(
      DocumentPolicy.detect(
        Uint8List.fromList([255, 216, 255, 224]),
        'photo.jpg',
      ),
      'image/jpeg',
    );
    expect(
      DocumentPolicy.detect(
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        'photo.png',
      ),
      'image/png',
    );
    expect(
      () => DocumentPolicy.detect(
        Uint8List.fromList([60, 104, 116, 109, 108]),
        'fake.pdf',
      ),
      throwsFormatException,
    );
    expect(
      () => DocumentPolicy.detect(
        Uint8List.fromList([37, 80, 68, 70, 45]),
        'fake.html',
      ),
      throwsFormatException,
    );
    expect(
      () => DocumentPolicy.detect(Uint8List(0), 'empty.pdf'),
      throwsFormatException,
    );
    expect(
      () => DocumentPolicy.detect(
        Uint8List(DocumentPolicy.maxBytes + 1),
        'big.pdf',
      ),
      throwsFormatException,
    );
  });
  test('TC-DOC-01 HU-08 nombre obligatorio y sin ruta proporcionada', () {
    expect(DocumentPolicy.folderName('  Salud  '), 'Salud');
    for (final value in ['', '   ', '../private', 'a/b', 'a\\b']) {
      expect(() => DocumentPolicy.folderName(value), throwsFormatException);
    }
  });
}
