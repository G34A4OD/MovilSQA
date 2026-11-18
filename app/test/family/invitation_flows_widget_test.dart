import 'dart:async';
import 'package:app/features/family/domain/invitation_repository.dart';
import 'package:app/features/family/presentation/family_page.dart';
import 'package:app/features/family/presentation/invitations_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'family_view_model_test.dart' show FakeFamilies;
import 'invitation_view_model_test.dart' show FakeInvitations;
import '../identity/profile_view_model_test.dart' show FakeProfiles;

InvitationRecord pending({bool expired = false}) => InvitationRecord(
  id: 'inv',
  familyId: 'grupo',
  familyName: 'Familia ficticia',
  targetName: 'Persona',
  status: 'pending',
  expiresAt: DateTime(expired ? 2000 : 2099),
);

class DelayedInvitations extends FakeInvitations {
  final gate = Completer<void>();
  @override
  Future<void> respond(String id, String decision, String requestId) async {
    await gate.future;
    await super.respond(id, decision, requestId);
  }
}

void main() {
  testWidgets('TC-FAM-02 HU-04: buscar ID e invitar; ID incompleto no busca', (
    tester,
  ) async {
    final repo = FakeInvitations();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InvitationsPanel(
              repository: repo,
              familyId: 'grupo',
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'corto');
    await tester.tap(find.text('Buscar familiar'));
    await tester.pumpAndSettle();
    expect(repo.lookups, 0);
    expect(find.text('Enviar invitación'), findsNothing);
    await tester.enterText(find.byType(TextField), 'a' * 32);
    await tester.tap(find.text('Buscar familiar'));
    await tester.pumpAndSettle();
    expect(repo.lookups, 1);
    await tester.ensureVisible(find.text('Enviar invitación'));
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();
    expect(repo.ids, hasLength(1));
    expect(find.text('Enviar invitación'), findsNothing);
  });
  testWidgets('TC-FAM-03 HU-04: rechazar y bloquear invitación caducada', (
    tester,
  ) async {
    final repo = FakeInvitations()..values = [pending()];
    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InvitationsPanel(
              repository: repo,
              onChanged: () => changed++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(repo.ids, hasLength(1));
    expect(changed, 1);
    expect(find.text('No hay invitaciones pendientes.'), findsOneWidget);
    repo.values = [pending(expired: true)];
    await tester.tap(find.byTooltip('Actualizar invitaciones'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceptar'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Rechazar'),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('TC-FAM-01 HU-03: crear familia y rechazar nombre inválido', (
    tester,
  ) async {
    final repo = FakeFamilies()..values = [];
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyPage(
          repository: repo,
          profiles: FakeProfiles(),
          reauthenticate: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear familia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'A');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.ids, isEmpty);
    await tester.tap(find.text('Crear familia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hogar ficticio');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.ids, hasLength(1));
  });
  testWidgets(
    'TC-FAM-03 HU-04: respuesta tardía no refresca pantalla cerrada',
    (tester) async {
      final repo = DelayedInvitations()..values = [pending()];
      var changed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InvitationsPanel(
                repository: repo,
                onChanged: () => changed++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      repo.gate.complete();
      await tester.pumpAndSettle();
      expect(changed, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
