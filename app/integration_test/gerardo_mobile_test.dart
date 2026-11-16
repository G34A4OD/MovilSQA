import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/main.dart' as app;
import 'package:app/core/secure_session_storage.dart';
import 'package:app/features/family/domain/relationship_repository.dart';
import 'package:app/features/family/presentation/family_tree.dart';

const email = String.fromEnvironment('E2E_EMAIL');
const password = String.fromEnvironment('E2E_PASSWORD');
const friendEmail = String.fromEnvironment('E2E_FRIEND_EMAIL');
const friendPassword = String.fromEnvironment('E2E_FRIEND_PASSWORD');
const friendId = String.fromEnvironment('E2E_FRIEND_PUBLIC_ID');
const familyName = String.fromEnvironment('E2E_FAMILY_NAME');
const newPassword = String.fromEnvironment('E2E_NEW_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'TC-MOB-G HU-01..07: registro PKCE, familia y permisos en Android real',
    (tester) async {
      expect(const bool.fromEnvironment('SUPABASE_LOCAL_TEST'), true);
      expect(email.endsWith('@example.test'), true);
      const storage = SecureSessionStorage(
        nidoSecureStorage,
        projectHost: '127.0.0.1',
      );
      await storage.removePersistedSession();
      await app.main();
      final cases = <String>[];
      void passed(String label) {
        cases.add(label);
        debugPrint('PASS_CASE: $label');
      }

      Future<void> until(Finder finder, {bool absent = false}) async {
        final clock = Stopwatch()..start();
        while (clock.elapsed < const Duration(seconds: 45)) {
          await tester.pump(const Duration(milliseconds: 200));
          final exists = finder.evaluate().isNotEmpty;
          if (exists != absent) {
            return;
          }
          final error = tester.takeException();
          if (error != null) {
            throw error;
          }
        }
        fail('Timed out waiting for expected mobile UI state: $finder');
      }

      Future<void> tap(String text) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 200));
        final candidates = find.text(text);
        if (candidates.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            candidates,
            250,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 30,
          );
        }
        final finder = candidates.last;
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 200));
      }

      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      Future<void> fill(String label, String value) async {
        final target = field(label);
        await until(target);
        await tester.ensureVisible(target);
        await tester.enterText(target, value);
      }

      Future<void> top() async {
        FocusManager.instance.primaryFocus?.unfocus();
        // A drag through the tree is consumed by its InteractiveViewer. Move
        // the containing list rather than panning the genealogy canvas.
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final bytes = await binding.takeScreenshot(name);
        // Android-only suite. The host copies each PNG before flutter test
        // uninstalls the integration APK, and acknowledges the copy.
        final output = Directory('/data/data/com.sqa.app/cache/nido-e2e');
        await output.create(recursive: true);
        await File('${output.path}/$name.png').writeAsBytes(bytes);
        debugPrint('CAPTURE_READY: $name');
        final ack = File('${output.path}/$name.copied');
        final clock = Stopwatch()..start();
        while (!await ack.exists() &&
            clock.elapsed < const Duration(seconds: 30)) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(await ack.exists(), true, reason: 'Host must preserve $name');
      }

      Future<void> logout() async {
        await tester.tap(find.byTooltip('Cerrar sesión en este dispositivo'));
        await until(find.text('Bienvenido a tu Nido'));
      }

      Future<void> login(String who, String secret) async {
        await fill('Correo electrónico', who);
        await fill('Contraseña', secret);
        await tap('Entrar');
        await until(find.text('Tu ID para invitaciones'));
      }

      await until(find.text('Bienvenido a tu Nido'));
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await tap('Crear una cuenta');
      await fill('Correo electrónico', email);
      await fill('Contraseña', password);
      await tap('Crear cuenta');
      // Host helper reads only this synthetic message from LOCAL Mailpit and opens
      // the verified nido:// callback via adb. The app exchanges its real PKCE code.
      await until(find.text('Conozcámonos'));
      passed('TC-AUTH-01: registro y confirmación PKCE por enlace Android');
      await fill('Nombre completo', 'Persona Móvil Uno');
      await fill('Carnet de identidad', 'FICTICIO-MOVIL');
      await fill('Nacimiento (AAAA-MM-DD)', '2000-01-01');
      await fill('Domicilio', 'Domicilio ficticio');
      await tap('Guardar perfil');
      await until(find.text('Tu ID para invitaciones'));
      passed('TC-PRO-01: perfil guardado contra PostgreSQL desde teléfono');
      expect(await storage.hasAccessToken(), true);
      expect(
        await const SecureSessionStorage(
          nidoSecureStorage,
          projectHost: '127.0.0.1',
        ).accessToken(),
        isNotNull,
      );
      passed(
        'TC-SEC-03: sesión persistida mediante almacenamiento seguro nativo',
      );
      await tap('Mis familias');
      await until(find.text('Crear familia'));
      await tap('Crear familia');
      await fill('Nombre de la familia', familyName);
      await tap('Guardar');
      await until(find.text(familyName));
      await tap(familyName);
      await until(find.text('Nuestro hogar'));
      passed('TC-FAM-01: creación y consulta del grupo real');
      await tap('Añadir mascota');
      await fill('Nombre de la mascota', 'Luna dispositivo');
      await fill('Especie', 'Perro');
      await tap('Guardar mascota');
      await until(find.text('Luna dispositivo'));
      await tester.ensureVisible(find.text('Luna dispositivo'));
      await tester.pumpAndSettle();
      await capture('01-mascota-android');
      passed('TC-FAM-06: mascota creada en ficha separada');
      await top();
      await fill('ID único del usuario', friendId);
      await tap('Buscar familiar');
      await until(find.text('Enviar invitación'));
      await tap('Enviar invitación');
      await until(find.textContaining('Invitación enviada.'));
      passed('TC-FAM-02: búsqueda Edge e invitación desde Android');
      await tester.tap(find.byTooltip('Volver a mis familias'));
      await tester.pump();
      await tester.pageBack();
      await until(find.text('Tu ID para invitaciones'));
      await logout();
      await login(friendEmail, friendPassword);
      await tap('Mis familias');
      await until(find.text('Aceptar'));
      await tap('Aceptar');
      await until(find.text('No hay invitaciones pendientes.'));
      await until(find.text(familyName));
      await tap(familyName);
      await until(find.text('Nuestro hogar'));
      await until(find.text('Luna dispositivo'));
      expect(find.text('Añadir mascota'), findsNothing);
      passed(
        'TC-FAM-03/06: receptor acepta y lee mascota sin acciones de admin',
      );
      await tester.tap(find.byTooltip('Volver a mis familias'));
      await tester.pump();
      await tester.pageBack();
      await until(find.text('Tu ID para invitaciones'));
      await logout();
      await login(email, password);
      await tap('Mis familias');
      await until(find.text(familyName));
      await tap(familyName);
      await until(find.text('Nuestro hogar'));
      await tap('Asignar parentesco');
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persona Móvil Uno').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persona Móvil Dos').last);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<FamilyRole>), findsOneWidget);
      await tap('Guardar vínculo');
      await until(
        find.text('Persona Móvil Uno · Padre / madre de Persona Móvil Dos'),
      );
      await tester.ensureVisible(find.byType(FamilyTree));
      await capture('02-arbol-android');
      passed('TC-FAM-05: rol referenciado y árbol en dispositivo');
      await top();
      await tap('Elegir qué datos comparto');
      await until(find.text('Confirmar consentimiento'));
      await tester.tap(find.text('Tipo de sangre'));
      await tap('Confirmar consentimiento');
      await until(
        find.text('Preferencias de información compartida guardadas.'),
      );
      passed('TC-PRO-03: consentimiento explícito por grupo');
      await tester.tap(find.byTooltip('Volver a mis familias'));
      await tester.pump();
      await tester.pageBack();
      await until(find.text('Tu ID para invitaciones'));
      final jwt = Supabase.instance.client.auth.currentSession!.accessToken;
      final userId = Supabase.instance.client.auth.currentUser!.id;
      expect(
        await Supabase.instance.client
            .from('private_profiles')
            .select('user_id')
            .eq('user_id', userId),
        hasLength(1),
      );
      await logout();
      final adversary = SupabaseClient(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        accessToken: () async => jwt,
      );
      expect(
        await adversary.from('private_profiles').select('user_id'),
        isEmpty,
      );
      await adversary.dispose();
      passed(
        'TC-SEC-03: JWT anterior al logout sin filas privadas desde Android',
      );
      await tap('Olvidé mi contraseña');
      await fill('Correo electrónico', email);
      await tap('Enviar instrucciones');
      await until(find.text('Nueva contraseña'));
      await fill('Nueva contraseña (mínimo 12 caracteres)', newPassword);
      await tap('Guardar contraseña');
      await until(find.text('Tu ID para invitaciones'));
      passed(
        'TC-AUTH-03: recuperación PKCE y cambio de contraseña en teléfono',
      );
      await logout();
      await login(email, newPassword);
      passed('TC-AUTH-02: acceso con contraseña nueva');
      await capture('03-cuenta-android');
      await logout();
      binding.reportData = {
        'cases': cases,
        'environment': 'Android real / Supabase local / datos ficticios',
      };
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
