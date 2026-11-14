import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TC-UI-01 HU-14 navegar y agregar monto exacto en demo', (
    tester,
  ) async {
    await tester.pumpWidget(const NidoApp());
    expect(
      find.text('Demostración local · Datos ficticios en memoria'),
      findsOneWidget,
    );
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
}
