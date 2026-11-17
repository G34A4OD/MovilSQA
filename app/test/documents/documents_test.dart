import 'dart:typed_data';

import 'package:app/features/documents/domain/document_repository.dart';
import 'package:app/features/documents/presentation/document_view_model.dart';
import 'package:app/features/documents/presentation/folders_panel.dart';
import 'package:app/features/documents/domain/folder_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'folders_test.dart' show FakeFolders;

class FakeDocuments implements DocumentRepository {
  final uploads = <DocumentUploadInput>[];
  final processed = <String>[];
  final deleted = <String>[];
  final downloaded = <String>[];
  List<DocumentRecord> values = [];
  bool fail = false;
  DocumentProcessResult processResult = const DocumentProcessResult(
    status: DocumentStatus.quarantine,
    error: 'scanner_unavailable',
  );

  @override
  Future<List<DocumentRecord>> listByFolder(String folderId) async =>
      values.where((d) => d.folderId == folderId).toList();

  @override
  Future<DocumentRecord> upload(
    String folderId,
    DocumentUploadInput input,
  ) async {
    uploads.add(input);
    if (fail) {
      throw StateError('forbidden');
    }
    final record = DocumentRecord(
      id: 'doc-${values.length + 1}',
      folderId: folderId,
      familyId: 'familia',
      title: input.title.trim(),
      description: input.description,
      mimeType: input.mimeType,
      sizeBytes: input.bytes.length,
      status: DocumentStatus.quarantine,
      storagePath: 'path-${values.length + 1}',
      version: 1,
      expiresOn: input.expiresOn,
    );
    values = [...values, record];
    return record;
  }

  @override
  Future<DocumentProcessResult> process(String documentId) async {
    processed.add(documentId);
    if (fail) {
      throw StateError('forbidden');
    }
    values = [
      for (final doc in values)
        if (doc.id == documentId)
          DocumentRecord(
            id: doc.id,
            folderId: doc.folderId,
            familyId: doc.familyId,
            title: doc.title,
            description: doc.description,
            mimeType: doc.mimeType,
            sizeBytes: doc.sizeBytes,
            status: processResult.status,
            storagePath: doc.storagePath,
            version: doc.version + 1,
            expiresOn: doc.expiresOn,
            publishedPath: processResult.status == DocumentStatus.approved
                ? doc.storagePath
                : doc.publishedPath,
          )
        else
          doc,
    ];
    return processResult;
  }

  @override
  Future<DocumentRecord> updateMetadata({
    required String documentId,
    required String title,
    required String description,
    required int expectedVersion,
    DateTime? expiresOn,
  }) async {
    final index = values.indexWhere((d) => d.id == documentId);
    final doc = values[index];
    if (doc.version != expectedVersion) {
      throw StateError('version_conflict');
    }
    final updated = DocumentRecord(
      id: doc.id,
      folderId: doc.folderId,
      familyId: doc.familyId,
      title: title.trim(),
      description: description,
      mimeType: doc.mimeType,
      sizeBytes: doc.sizeBytes,
      status: doc.status,
      storagePath: doc.storagePath,
      version: doc.version + 1,
      expiresOn: expiresOn,
      publishedPath: doc.publishedPath,
    );
    values = [...values]..[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String documentId, int expectedVersion) async {
    deleted.add(documentId);
    values = values.where((d) => d.id != documentId).toList();
  }

  @override
  Future<DocumentDownload> download(String documentId) async {
    downloaded.add(documentId);
    return DocumentDownload(
      documentId: documentId,
      mimeType: 'application/pdf',
      bytes: Uint8List.fromList([37, 80, 68, 70, 45]),
    );
  }
}

Uint8List _pdf([int extra = 0]) =>
    Uint8List.fromList([37, 80, 68, 70, 45, 49, ...List.filled(extra, 0)]);

void main() {
  test('TC-DOC-02 HU-09: input exige título, tipo y tamaño', () {
    final ok = DocumentUploadInput(
      title: '  Vacunas  ',
      description: 'Ejemplo ficticio',
      filename: 'vacunas.pdf',
      bytes: _pdf(),
    );
    expect(ok.isValid, true);
    expect(ok.mimeType, 'application/pdf');
    expect(
      DocumentUploadInput(
        title: '',
        description: '',
        filename: 'vacunas.pdf',
        bytes: _pdf(),
      ).isValid,
      false,
    );
    expect(
      DocumentUploadInput(
        title: 'Vacunas',
        description: '',
        filename: 'fake.pdf',
        bytes: Uint8List.fromList([60, 104, 116, 109, 108]),
      ).isValid,
      false,
    );
  });

  test('TC-DOC-02 HU-09: carga válida queda en cuarentena', () async {
    final repo = FakeDocuments();
    final vm = DocumentViewModel(repo, 'carpeta-1');
    addTearDown(vm.dispose);
    expect(
      await vm.upload(
        DocumentUploadInput(
          title: 'Vacunas',
          description: 'Nota ficticia',
          filename: 'vacunas.pdf',
          bytes: _pdf(),
        ),
      ),
      true,
    );
    expect(repo.uploads, hasLength(1));
    expect(vm.items.single.status, DocumentStatus.quarantine);
    expect(vm.items.single.title, 'Vacunas');
  });

  test('TC-DOC-02 HU-09: sin escáner process conserva cuarentena', () async {
    final repo = FakeDocuments();
    final vm = DocumentViewModel(repo, 'carpeta-1');
    addTearDown(vm.dispose);
    await vm.upload(
      DocumentUploadInput(
        title: 'Vacunas',
        description: '',
        filename: 'vacunas.pdf',
        bytes: _pdf(),
      ),
    );
    expect(await vm.process(vm.items.single), true);
    expect(repo.processed, ['doc-1']);
    expect(vm.items, hasLength(1));
    expect(vm.items.single.status, DocumentStatus.quarantine);
    expect(vm.message, contains('cuarentena'));
  });

  test('TC-DOC-03 HU-09: editar metadata y eliminar propio', () async {
    final repo = FakeDocuments();
    repo.processResult = const DocumentProcessResult(
      status: DocumentStatus.approved,
    );
    final vm = DocumentViewModel(repo, 'carpeta-1');
    addTearDown(vm.dispose);
    await vm.upload(
      DocumentUploadInput(
        title: 'Vacunas',
        description: '',
        filename: 'vacunas.pdf',
        bytes: _pdf(),
      ),
    );
    repo.processResult = const DocumentProcessResult(
      status: DocumentStatus.approved,
    );
    // Forzar approved en lista
    final doc = repo.values.single;
    repo.values = [
      DocumentRecord(
        id: doc.id,
        folderId: doc.folderId,
        familyId: doc.familyId,
        title: doc.title,
        description: doc.description,
        mimeType: doc.mimeType,
        sizeBytes: doc.sizeBytes,
        status: DocumentStatus.approved,
        storagePath: doc.storagePath,
        version: 2,
        publishedPath: doc.storagePath,
      ),
    ];
    await vm.load();
    expect(
      await vm.updateMetadata(
        document: vm.items.single,
        title: 'Vacunas editadas',
        description: 'nota',
      ),
      true,
    );
    expect(vm.items.single.title, 'Vacunas editadas');
    expect(await vm.download(vm.items.single), true);
    expect(repo.downloaded, [doc.id]);
    expect(await vm.delete(vm.items.single), true);
    expect(vm.items, isEmpty);
    expect(repo.deleted, [doc.id]);
  });

  test(
    'TC-DOC-02 HU-09: reemplazo reserva sin sobrescribir approved',
    () async {
      final repo = FakeDocuments();
      final approved = DocumentRecord(
        id: 'doc-old',
        folderId: 'carpeta-1',
        familyId: 'familia',
        title: 'Vacunas',
        description: '',
        mimeType: 'application/pdf',
        sizeBytes: 8,
        status: DocumentStatus.approved,
        storagePath: 'old-path',
        version: 2,
        publishedPath: 'old-path',
      );
      repo.values = [approved];
      final vm = DocumentViewModel(repo, 'carpeta-1');
      addTearDown(vm.dispose);
      await vm.load();
      expect(
        await vm.replace(
          approved,
          DocumentUploadInput(
            title: 'Vacunas v2',
            description: 'reemplazo',
            filename: 'v2.pdf',
            bytes: _pdf(),
          ),
        ),
        true,
      );
      expect(repo.uploads.single.replacesDocumentId, 'doc-old');
      expect(
        vm.items.where((d) => d.status == DocumentStatus.approved),
        isNotEmpty,
      );
      expect(
        vm.items.where((d) => d.status == DocumentStatus.quarantine),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'TC-DOC-02 HU-09: formulario reserva carga con archivo inyectado',
    (tester) async {
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
                pickDocumentBytes: () async =>
                    (filename: 'vacunas.pdf', bytes: _pdf()),
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
      await tester.enterText(
        find.byKey(const Key('document-title')),
        'Vacunas',
      );
      await tester.enterText(
        find.byKey(const Key('document-description')),
        'Ejemplo ficticio',
      );
      await tester.tap(find.byKey(const Key('document-pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('document-save')));
      await tester.pumpAndSettle();
      expect(docs.uploads, hasLength(1));
      expect(find.textContaining('cuarentena'), findsWidgets);
      expect(find.text('Vacunas'), findsWidgets);
    },
  );
}
