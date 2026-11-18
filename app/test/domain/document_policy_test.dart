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
    expect(DocumentPolicy.folderName('a' * 100), 'a' * 100);
    for (final value in [
      '',
      '   ',
      '../private',
      'a/b',
      'a\\b',
      'linea\nnueva',
      'a' * 101,
    ]) {
      expect(() => DocumentPolicy.folderName(value), throwsFormatException);
    }
  });

  test('TC-DOC-02 HU-09 título, descripción y vencimiento opcionales', () {
    expect(DocumentPolicy.title('  Vacunas  '), 'Vacunas');
    expect(DocumentPolicy.description('nota'), 'nota');
    expect(() => DocumentPolicy.description('x' * 1001), throwsFormatException);
    final today = DateTime(2026, 11, 16);
    expect(DocumentPolicy.expiresOn(null, today: today), isNull);
    expect(
      DocumentPolicy.expiresOn(DateTime(2026, 11, 16), today: today),
      DateTime(2026, 11, 16),
    );
    expect(
      () => DocumentPolicy.expiresOn(DateTime(2026, 11, 15), today: today),
      throwsFormatException,
    );
  });
}
