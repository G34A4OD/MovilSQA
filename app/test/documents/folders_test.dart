import 'package:app/features/documents/domain/folder_repository.dart';
import 'package:app/features/documents/presentation/folder_view_model.dart';
import 'package:app/features/documents/presentation/folders_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFolders implements FolderRepository {
  List<FolderRecord> values = [];
  final creates = <FolderInput>[];
  bool fail = false;

  @override
  Future<List<FolderRecord>> list(String familyId) async =>
      values.where((f) => f.familyId == familyId).toList();

  @override
  Future<FolderRecord> create(String familyId, FolderInput input) async {
    creates.add(input);
    if (fail) {
      throw StateError('forbidden');
    }
    final record = FolderRecord(
      id: 'carpeta-${values.length + 1}',
      familyId: familyId,
      name: input.name.trim(),
      version: 1,
      ownerKind: input.ownerKind,
      ownerUserId: input.ownerKind == FolderOwnerKind.human ? 'yo' : null,
      petId: input.petId,
    );
    values = [...values, record];
    return record;
  }

  @override
  Future<FolderRecord> rename(FolderRecord folder, String name) async {
    if (fail) {
      throw StateError('version_conflict');
    }
    final updated = FolderRecord(
      id: folder.id,
      familyId: folder.familyId,
      name: name.trim(),
      version: folder.version + 1,
      ownerKind: folder.ownerKind,
      ownerUserId: folder.ownerUserId,
      petId: folder.petId,
    );
    values = [
      for (final item in values)
        if (item.id == folder.id) updated else item,
    ];
    return updated;
  }

  @override
  Future<void> delete(FolderRecord folder) async {
    values = values.where((item) => item.id != folder.id).toList();
  }
}

void main() {
  test('TC-DOC-01 HU-08: input exige nombre y titular XOR', () {
    expect(
      const FolderInput(name: 'Salud', ownerKind: FolderOwnerKind.human).isValid,
      true,
    );
    expect(
      const FolderInput(
        name: 'a/b',
        ownerKind: FolderOwnerKind.human,
      ).isValid,
      false,
    );
    expect(
      const FolderInput(
        name: 'Vacunas',
        ownerKind: FolderOwnerKind.pet,
        petId: 'mascota',
      ).isValid,
      true,
    );
    expect(
      const FolderInput(name: 'Vacunas', ownerKind: FolderOwnerKind.pet).isValid,
      false,
    );
  });

  test('TC-DOC-01 HU-08: CRUD de carpeta propia conserva versión', () async {
    final repo = FakeFolders();
    final vm = FolderViewModel(repo, 'familia', isAdmin: false);
    addTearDown(vm.dispose);
    expect(
      await vm.create(
        const FolderInput(name: '  Salud  ', ownerKind: FolderOwnerKind.human),
      ),
      true,
    );
    expect(vm.items.single.name, 'Salud');
    expect(
      await vm.create(
        const FolderInput(
          name: 'Mascota',
          ownerKind: FolderOwnerKind.pet,
          petId: 'luna',
        ),
      ),
      false,
    );
    expect(repo.creates.where((c) => c.ownerKind == FolderOwnerKind.pet), isEmpty);
    expect(await vm.rename(vm.items.single, 'Salud familiar'), true);
    expect(vm.items.single.version, 2);
    expect(await vm.delete(vm.items.single), true);
    expect(vm.items, isEmpty);
  });

  testWidgets(
    'TC-DOC-01 HU-08: miembro crea carpeta propia y confirma borrado',
    (tester) async {
      final repo = FakeFolders();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FoldersPanel(
                repository: repo,
                familyId: 'familia',
                isAdmin: false,
                currentUserId: 'yo',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('folder-create')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('folder-owner-kind')), findsNothing);
      await tester.enterText(find.byKey(const Key('folder-name')), 'Identidad');
      await tester.tap(find.byKey(const Key('folder-save')));
      await tester.pumpAndSettle();
      expect(find.text('Identidad'), findsOneWidget);
      await tester.tap(find.byTooltip('Opciones de Identidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar carpeta'));
      await tester.pumpAndSettle();
      expect(find.text('Identidad'), findsNothing);
    },
  );

  testWidgets(
    'TC-DOC-01 HU-08: admin puede elegir mascota; nombre inválido no llama repo',
    (tester) async {
      final repo = FakeFolders();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FoldersPanel(
                repository: repo,
                familyId: 'familia',
                isAdmin: true,
                currentUserId: 'admin',
                pets: const [
                  FolderPetOption(id: 'luna', name: 'Luna ficticia'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('folder-create')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('folder-owner-kind')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('folder-name')), 'a/b');
      await tester.tap(find.byKey(const Key('folder-save')));
      await tester.pumpAndSettle();
      expect(repo.creates, isEmpty);
      expect(find.textContaining('sin rutas'), findsOneWidget);
    },
  );
}
