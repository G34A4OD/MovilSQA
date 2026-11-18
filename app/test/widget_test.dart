import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TC-UI-01 HU-14 navegar y agregar monto exacto en demo', (
    tester,
  ) async {
    await tester.pumpWidget(const NidoApp());
    expect(find.textContaining('Demostración'), findsNothing);
    expect(find.textContaining('ficticio'), findsNothing);
    await tester.tap(find.byKey(const Key('budget-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Bs 2350,00'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('new-entry')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('new-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('entry-amount')), '0,10');
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('annual-balance')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bs 2350,10'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('TC-UI-01 HU-13 monto inválido conserva formulario', (
    tester,
  ) async {
    await tester.pumpWidget(const NidoApp());
    await tester.tap(find.byKey(const Key('budget-tab')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('new-entry')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('new-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('entry-amount')), '-1');
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo movimiento'), findsOneWidget);
    expect(
      find.text('Usa un monto positivo con hasta dos decimales.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('TC-UI-02 HU-03 avatar abre la familia', (tester) async {
    await tester.pumpWidget(const NidoApp());
    expect(find.text('Tu ID para invitaciones'), findsNothing);
    await tester.tap(find.byTooltip('Ver mi familia'));
    await tester.pumpAndSettle();
    expect(find.text('Tu ID para invitaciones'), findsOneWidget);
  });
  testWidgets('TC-UI-03 HU-04 aceptar invitación e invitar en la demo', (
    tester,
  ) async {
    await tester.pumpWidget(const NidoApp());
    await tester.tap(find.byTooltip('Ver mi familia'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Aceptar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(find.text('Te uniste a Familia Quispe'), findsOneWidget);
    expect(find.text('No hay invitaciones pendientes.'), findsOneWidget);
    expect(find.text('Familia Quispe'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.text('Familia Quispe')),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.scrollUntilVisible(
      find.text('Enviar invitación'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(field, 'corto');
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pega el ID completo: 32 letras y números.'),
      findsOneWidget,
    );
    await tester.enterText(field, 'b' * 32);
    await tester.ensureVisible(find.text('Enviar invitación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();
    expect(find.text('Invitación enviada'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
