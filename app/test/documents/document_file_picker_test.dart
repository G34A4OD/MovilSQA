import 'dart:typed_data';

import 'package:app/features/documents/data/document_file_picker.dart';
import 'package:app/features/documents/domain/document_policy.dart';
import 'package:app/features/documents/presentation/folders_panel.dart';
import 'package:app/features/documents/domain/folder_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'documents_test.dart' show FakeDocuments;
import 'folders_test.dart' show FakeFolders;

Uint8List _pdf() => Uint8List.fromList([37, 80, 68, 70, 45, 49]);
Uint8List _jpg() => Uint8List.fromList([255, 216, 255, 224]);
Uint8List _png() => Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0]);

void main() {
  test('TC-DOC-02 HU-09: prepareDocumentPick acepta PDF/JPG/PNG', () {
    expect(
      prepareDocumentPick(filename: 'a.pdf', bytes: _pdf()).filename,
      'a.pdf',
    );
    expect(
      prepareDocumentPick(filename: 'a.jpg', bytes: _jpg()).filename,
      'a.jpg',
    );
    expect(
      prepareDocumentPick(filename: 'a.png', bytes: _png()).filename,
      'a.png',
    );
  });

  test(
    'TC-DOC-02 HU-09: prepareDocumentPick rechaza >10 MiB y tipos inválidos',
    () {
      expect(
        () => prepareDocumentPick(
          filename: 'big.pdf',
          bytes: Uint8List(DocumentPolicy.maxBytes + 1),
        ),
        throwsFormatException,
      );
      expect(
        () => prepareDocumentPick(
          filename: 'fake.pdf',
          bytes: Uint8List.fromList([60, 104, 116, 109, 108]),
        ),
        throwsFormatException,
      );
      expect(
        () => prepareDocumentPick(filename: 'a.txt', bytes: _pdf()),
        throwsFormatException,
      );
    },
  );

  testWidgets('TC-DOC-02 HU-09: cancelar selector no crea reserva ni carga', (
    tester,
  ) async {
    final folders = FakeFolders();
    folders.values = [
      const FolderRecord(
        id: 'carpeta-1',
        familyId: 'familia',
        name: 'Salud',
        version: 1,
        ownerKind: FolderOwnerKind.human,
        ownerUserId: 'yo',
      ),
    ];
    final docs = FakeDocuments();
    var pickCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FoldersPanel(
              repository: folders,
              familyId: 'familia',
              isAdmin: false,
              currentUserId: 'yo',
              documents: docs,
              pickDocumentBytes: () async {
                pickCalls += 1;
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salud'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-pick')));
    await tester.pumpAndSettle();
    expect(pickCalls, 1);
    expect(docs.uploads, isEmpty);
    expect(find.byKey(const Key('document-title')), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(docs.uploads, isEmpty);
  });

  testWidgets('TC-DOC-02 HU-09: archivo >10 MiB no carga ni reserva', (
    tester,
  ) async {
    final folders = FakeFolders();
    folders.values = [
      const FolderRecord(
        id: 'carpeta-1',
        familyId: 'familia',
        name: 'Salud',
        version: 1,
        ownerKind: FolderOwnerKind.human,
        ownerUserId: 'yo',
      ),
    ];
    final docs = FakeDocuments();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FoldersPanel(
              repository: folders,
              familyId: 'familia',
              isAdmin: false,
              currentUserId: 'yo',
              documents: docs,
              pickDocumentBytes: () async => (
                filename: 'big.pdf',
                bytes: Uint8List(DocumentPolicy.maxBytes + 1),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salud'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-upload')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('document-title')), 'Grande');
    await tester.tap(find.byKey(const Key('document-pick')));
    await tester.pumpAndSettle();
    expect(find.textContaining('10 MiB'), findsOneWidget);
    expect(docs.uploads, isEmpty);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(docs.uploads, isEmpty);
  });
}
