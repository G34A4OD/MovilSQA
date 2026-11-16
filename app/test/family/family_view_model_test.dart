import 'package:app/features/family/domain/family_repository.dart';
import 'package:app/features/family/domain/invitation_repository.dart';
import 'invitation_view_model_test.dart' show FakeInvitations;
import 'package:app/features/family/presentation/family_view_model.dart';
import 'package:app/core/read_all.dart';
import 'package:app/core/connected_app.dart';
import 'package:app/features/identity/domain/auth_repository.dart';
import 'package:app/features/identity/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../identity/auth_view_model_test.dart' show FakeAuth;
import '../identity/profile_view_model_test.dart' show FakeProfiles, valid;

class FakeFamilies implements FamilyRepository {
  @override
  String? get currentUserId => 'persona';
  bool lastAdmin = false;
  @override
  Future<void> setAdmin(
    String familyId,
    String targetUserId,
    bool value,
  ) async {
    if (lastAdmin) {
      throw const FamilyFailure('last_admin');
    }
  }

  @override
  Future<void> leave(String familyId) async {
    if (lastAdmin) {
      throw const FamilyFailure('last_admin');
    }
    values = [];
  }

  @override
  Future<void> remove(String familyId, String targetUserId) async {}
  @override
  InvitationRepository get invitations => FakeInvitations();
  List<FamilyRecord> values = [
    const FamilyRecord(
      id: 'grupo-ficticio',
      name: 'Familia ficticia',
      version: 1,
      isAdmin: true,
    ),
  ];
  final ids = <String>[];
  bool fail = false;
  @override
  Future<List<FamilyRecord>> list() async => values;
  @override
  Future<List<FamilyMember>> members(String familyId) async => [
    const FamilyMember(
      userId: 'persona',
      fullName: 'Persona ficticia',
      publicId: 'aleatorio',
      isAdmin: true,
    ),
  ];
  @override
  Future<void> create(String name, String requestId) async {
    ids.add(requestId);
    if (fail) {
      throw StateError('network');
    }
  }

  @override
  Future<void> update(FamilyRecord family, String name) async {}
  @override
  Future<void> delete(FamilyRecord family, String confirmation) async {
    values = [];
  }
}

void main() {
  test(
    'TC-FAM-04 HU-05: último admin explica bloqueo y conserva selección',
    () async {
      final repo = FakeFamilies()..lastAdmin = true;
      final vm = FamilyViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      await vm.select(vm.families.first);
      expect(await vm.leave(vm.selected!), false);
      expect(vm.selected, isNotNull);
      expect(vm.message, contains('Designa otro'));
      repo.lastAdmin = false;
      expect(await vm.leave(vm.selected!), true);
      expect(vm.selected, isNull);
    },
  );
  test(
    'TC-FAM-01 HU-03: reintento conserva request_id y pérdida de acceso vacía selección',
    () async {
      final repo = FakeFamilies();
      final vm = FamilyViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      await vm.select(vm.families.first);
      expect(vm.members, hasLength(1));
      repo.fail = true;
      expect(await vm.create('Casa ficticia'), false);
      repo.fail = false;
      expect(await vm.create('Casa ficticia'), true);
      expect(repo.ids[0], repo.ids[1]);
      repo.values = [];
      await vm.load();
      expect(vm.selected, isNull);
      expect(vm.members, isEmpty);
    },
  );
  test(
    'TC-FAM-01 HU-03: paginación devuelve más de 100 familias sin omisiones',
    () async {
      final rows = List.generate(205, (i) => <String, dynamic>{'id': i});
      final starts = <int>[];
      final all = await readAll((from, to) async {
        starts.add(from);
        return rows.skip(from).take(to - from + 1).toList();
      });
      expect(all, hasLength(205));
      expect(all.last['id'], 204);
      expect(starts, [0, 100, 200]);
    },
  );
  testWidgets(
    'TC-AUTH-04 TC-SEC-03: logout elimina rutas y datos de la familia abierta',
    (tester) async {
      final auth = FakeAuth()
        ..currentSession = const IdentitySession(
          userId: 'persona',
          email: 'persona@example.test',
        );
      final profiles = FakeProfiles()
        ..value = const PersonalProfile(
          userId: 'persona',
          publicId: 'aleatorio',
          version: 1,
          details: valid,
        );
      await tester.pumpWidget(
        ConnectedNidoApp(
          auth: auth,
          profiles: profiles,
          families: FakeFamilies(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis familias'));
      await tester.pumpAndSettle();
      expect(find.text('Familia ficticia'), findsOneWidget);
      auth.events.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Familia ficticia'), findsNothing);
      expect(find.text('Bienvenido a tu Nido'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await auth.events.close();
    },
  );
}
