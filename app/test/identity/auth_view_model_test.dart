import 'dart:async';
import 'package:app/features/identity/domain/auth_repository.dart';
import 'package:app/features/identity/presentation/auth_view_model.dart';
import 'package:app/features/identity/presentation/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuth implements AuthRepository {
  final events = StreamController<IdentitySession?>.broadcast(sync: true);
  @override
  IdentitySession? currentSession;
  @override
  Stream<IdentitySession?> get sessions => events.stream;
  int calls = 0;
  bool fail = false;
  Completer<void>? pending;
  Future<void> action() async {
    calls++;
    if (fail) throw StateError('Internal sensitive detail');
    await pending?.future;
  }

  @override
  Future<void> register(String email, String password) => action();
  @override
  Future<void> signIn(String email, String password) => action();
  @override
  Future<void> sendRecovery(String email) => action();
  @override
  Future<void> updatePassword(String password) => action();
  @override
  Future<void> signOut() async {
    await action();
    currentSession = null;
    events.add(null);
  }
}

void main() {
  late FakeAuth repo;
  late AuthViewModel model;
  setUp(() {
    repo = FakeAuth();
    model = AuthViewModel(repo);
  });
  tearDown(() async {
    model.dispose();
    await repo.events.close();
  });
  testWidgets(
    'TC-AUTH-01/04 HU-01: formulario limpia contraseña y gate elimina cuenta al salir',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            model: model,
            signedInBuilder: (_, _) =>
                const Scaffold(body: Text('Sesión abierta')),
          ),
        ),
      );
      await tester.tap(find.text('Crear una cuenta'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'uno@example.test');
      await tester.enterText(find.byType(TextField).at(1), 'ClaveFicticia123!');
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Revisa tu correo'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
      repo.events.add(
        const IdentitySession(userId: 'ficticio', email: 'uno@example.test'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sesión abierta'), findsOneWidget);
      await model.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Sesión abierta'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'TC-AUTH-01 HU-01: alta exige contraseña fuerte y no presupone sesión',
    () async {
      model.changeMode(AuthMode.register);
      await model.submit('uno@example.test', 'corta');
      expect(repo.calls, 0);
      await model.submit('uno@example.test', 'ClaveFicticia123!');
      expect(repo.calls, 1);
      expect(model.session, isNull);
      expect(model.message, contains('confirmar'));
    },
  );
  test(
    'TC-AUTH-02 HU-01: error genérico no filtra respuesta interna',
    () async {
      repo.fail = true;
      await model.submit('uno@example.test', 'ClaveFicticia123!');
      expect(model.message, isNot(contains('sensitive')));
      expect(model.session, isNull);
      expect(model.busy, false);
    },
  );
  test(
    'TC-AUTH-01 HU-01: datos inválidos y doble envío no generan llamadas duplicadas',
    () async {
      await model.submit('sin-correo', 'clave');
      expect(repo.calls, 0);
      repo.pending = Completer<void>();
      final first = model.submit('uno@example.test', 'ClaveFicticia123!');
      await model.submit('uno@example.test', 'ClaveFicticia123!');
      expect(repo.calls, 1);
      repo.pending!.complete();
      await first;
    },
  );
  test(
    'TC-AUTH-03 HU-01: recuperación no confirma existencia de cuenta',
    () async {
      model.changeMode(AuthMode.recover);
      await model.submit('nadie@example.test', '');
      expect(model.message, contains('Si el correo'));
      expect(model.session, isNull);
    },
  );
  test(
    'TC-AUTH-03 HU-01: enlace de recuperación exige nueva contraseña y limpia estado',
    () async {
      repo.events.add(
        const IdentitySession(
          userId: 'ficticio',
          email: 'uno@example.test',
          recovery: true,
        ),
      );
      expect(model.recovery, true);
      await model.savePassword('corta');
      expect(repo.calls, 0);
      expect(model.recovery, true);
      await model.savePassword('NuevaClaveFicticia123!');
      expect(model.recovery, false);
      await model.signOut();
      expect(model.session, isNull);
    },
  );
  test('TC-AUTH-04 HU-01: logout fallido no finge revocación remota', () async {
    repo.events.add(
      const IdentitySession(userId: 'ficticio', email: 'uno@example.test'),
    );
    repo.fail = true;
    await model.signOut();
    expect(model.session, isNotNull);
    repo.fail = false;
    await model.signOut();
    expect(model.session, isNull);
  });
}
