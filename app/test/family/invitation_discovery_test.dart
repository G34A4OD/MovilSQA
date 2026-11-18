import 'package:app/features/family/presentation/family_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'family_view_model_test.dart' show FakeFamilies;
import '../identity/profile_view_model_test.dart' show FakeProfiles;

void main() {
  testWidgets('TC-FAM-03 HU-04: ID visible y copiable sin familia', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyPage(
          repository: FakeFamilies()..values = [],
          profiles: FakeProfiles(),
          reauthenticate: (_) async {},
          invitationId: 'id-ficticio',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('id-ficticio'), findsOneWidget);
    await tester.tap(find.text('Copiar ID'));
    await tester.pump();
    expect(copied, 'id-ficticio');
    expect(find.text('ID copiado.'), findsOneWidget);
  });
  testWidgets('TC-FAM-03 HU-04: no se inventa ID ausente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyPage(
          repository: FakeFamilies()..values = [],
          profiles: FakeProfiles(),
          reauthenticate: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu ID para invitaciones'), findsNothing);
    expect(find.text('Copiar ID'), findsNothing);
  });
  testWidgets('TC-FAM-03 HU-04: ID accesible con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: FamilyPage(
          repository: FakeFamilies()..values = [],
          profiles: FakeProfiles(),
          reauthenticate: (_) async {},
          invitationId: 'a' * 32,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu ID para invitaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
