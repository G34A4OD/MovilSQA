import 'package:app/features/family/domain/pet_repository.dart';
import 'package:app/features/family/presentation/pet_view_model.dart';
import 'package:app/features/family/presentation/pets_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePets implements PetRepository {
  List<PetRecord> values = [];
  bool fail = false;
  final requests = <String>[];
  @override
  Future<List<PetRecord>> list(String familyId) async => values;
  @override
  Future<void> save(
    String familyId,
    PetInput input,
    String requestId, {
    PetRecord? existing,
  }) async {
    requests.add(requestId);
    if (fail) {
      throw StateError('version_conflict');
    }
    values = [
      PetRecord(
        id: existing?.id ?? 'mascota-ficticia',
        version: (existing?.version ?? 0) + 1,
        details: input,
      ),
    ];
  }

  @override
  Future<void> delete(PetRecord pet) async {
    values = [];
  }
}

void main() {
  test('TC-FAM-06 HU-07: fecha opcional y límites, sin identidad humana', () {
    expect(const PetInput(name: 'Luna', species: 'Perro').isValid, true);
    expect(const PetInput(name: '', species: 'Perro').isValid, false);
    expect(
      const PetInput(
        name: 'Luna',
        species: 'Perro',
        birthDate: '2023-02-29',
      ).isValid,
      false,
    );
    expect(
      const PetInput(
        name: 'Luna',
        species: 'Perro',
      ).fields.containsKey('user_id'),
      false,
    );
  });
  test(
    'TC-FAM-06 HU-07: reintento estable y CRUD conserva versión esperada',
    () async {
      final repo = FakePets();
      final vm = PetViewModel(repo, 'familia');
      addTearDown(vm.dispose);
      const input = PetInput(name: 'Luna ficticia', species: 'Perro');
      repo.fail = true;
      expect(await vm.save(input), false);
      repo.fail = false;
      expect(await vm.save(input), true);
      expect(repo.requests[0], repo.requests[1]);
      await vm.save(
        const PetInput(name: 'Luna editada', species: 'Perro'),
        existing: vm.items.first,
      );
      expect(vm.items.first.version, 2);
      await vm.delete(vm.items.first);
      expect(vm.items, isEmpty);
    },
  );
  testWidgets(
    'TC-FAM-06 HU-07: miembro ve ficha separada y no acciones de admin',
    (tester) async {
      final repo = FakePets()
        ..values = [
          const PetRecord(
            id: 'ficticia',
            version: 1,
            details: PetInput(name: 'Luna ficticia', species: 'Perro'),
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PetsPanel(
                repository: repo,
                familyId: 'familia',
                isAdmin: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Luna ficticia'), findsOneWidget);
      expect(find.text('Añadir mascota'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
