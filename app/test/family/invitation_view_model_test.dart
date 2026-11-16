import 'package:app/features/family/domain/invitation_repository.dart';
import 'package:app/features/family/presentation/invitation_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app/features/family/presentation/invitations_panel.dart';

class FakeInvitations implements InvitationRepository {
  List<InvitationRecord> values = [];
  bool fail = false;
  int lookups = 0;
  final ids = <String>[];
  @override
  Future<List<InvitationRecord>> received() async => values;
  @override
  Future<List<InvitationRecord>> sent(String familyId) async => values;
  @override
  Future<InvitationCandidate?> lookup(String familyId, String publicId) async {
    lookups++;
    return InvitationCandidate(
      publicId: publicId,
      fullName: 'Persona ficticia',
    );
  }

  @override
  Future<void> invite(
    String familyId,
    String publicId,
    String requestId,
  ) async {
    ids.add(requestId);
    if (fail) {
      throw StateError('network');
    }
  }

  @override
  Future<void> respond(
    String invitationId,
    String decision,
    String requestId,
  ) async {
    ids.add(requestId);
    if (fail) {
      throw StateError('network');
    }
    values = [];
  }

  @override
  Future<void> revoke(String invitationId) async {
    values = [];
  }
}

void main() {
  testWidgets(
    'TC-FAM-03 HU-04: invitación recibida se acepta desde pantalla y refresca grupos',
    (tester) async {
      final repo = FakeInvitations()
        ..values = [
          InvitationRecord(
            id: 'ficticia',
            familyId: 'grupo',
            familyName: 'Familia ficticia',
            targetName: 'Persona',
            status: 'pending',
            expiresAt: DateTime(2099),
          ),
        ];
      var changed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InvitationsPanel(
                repository: repo,
                onChanged: () => changed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Familia ficticia'), findsOneWidget);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(changed, true);
      expect(find.text('No hay invitaciones pendientes.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'TC-FAM-02 HU-04: ID incompleto no busca; editar lo buscado retira candidato',
    () async {
      final repo = FakeInvitations();
      final vm = InvitationViewModel(repo, familyId: 'grupo');
      addTearDown(vm.dispose);
      await vm.lookup('parcial');
      expect(repo.lookups, 0);
      expect(vm.candidate, isNull);
      await vm.lookup('a' * 32);
      expect(repo.lookups, 1);
      expect(vm.candidate, isNotNull);
      vm.clearCandidate();
      expect(vm.candidate, isNull);
    },
  );
  test(
    'TC-FAM-02/03 HU-04: reintentos conservan request, éxito actualiza pendientes',
    () async {
      final repo = FakeInvitations();
      final vm = InvitationViewModel(repo, familyId: 'grupo');
      addTearDown(vm.dispose);
      await vm.lookup('a' * 32);
      repo.fail = true;
      expect(await vm.invite(), false);
      repo.fail = false;
      expect(await vm.invite(), true);
      expect(repo.ids[0], repo.ids[1]);
      expect(vm.candidate, isNull);
      final pending = InvitationRecord(
        id: 'ficticia',
        familyId: 'grupo',
        familyName: 'Familia',
        targetName: 'Persona',
        status: 'pending',
        expiresAt: DateTime(2099),
      );
      repo.values = [pending];
      await vm.load();
      expect(vm.items, hasLength(1));
      expect(await vm.respond(pending, 'accept'), true);
      expect(vm.items, isEmpty);
    },
  );
}
