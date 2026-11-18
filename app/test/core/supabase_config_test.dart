import 'package:app/core/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('La compilación normal usa el proyecto compartido de pruebas', () {
    const config = SupabaseConfig.forBuild;
    config.validate();
    expect(Uri.parse(config.url).host, 'dcwfnnttrxbtavshrbfj.supabase.co');
    expect(config.localTest, isFalse);
  });

  test(
    'TC-SEC-01: HTTP solo loopback de pruebas con bandera explícita y build debug',
    () {
      const SupabaseConfig(
        url: 'http://127.0.0.1:54321',
        publishableKey: 'sb_publishable_ficticio',
        localTest: true,
      ).validate();
      expect(
        () => const SupabaseConfig(
          url: 'http://127.0.0.1:54321',
          publishableKey: 'sb_publishable_ficticio',
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => const SupabaseConfig(
          url: 'http://192.168.1.3:54321',
          publishableKey: 'sb_publishable_ficticio',
          localTest: true,
        ).validate(),
        throwsFormatException,
      );
    },
  );
  test(
    'TC-SEC-01: solo configuración pública HTTPS, sin credenciales de servidor',
    () {
      const SupabaseConfig(
        url: 'https://demo.supabase.co',
        publishableKey: 'sb_publishable_ficticio',
      ).validate();
      for (final key in ['sb_secret_ficticio', 'service_role', '']) {
        expect(
          () => SupabaseConfig(
            url: 'https://demo.supabase.co',
            publishableKey: key,
          ).validate(),
          throwsFormatException,
        );
      }
      for (final url in [
        'http://demo.supabase.co',
        'https://user:pass@demo.supabase.co',
        'https://demo.supabase.co/rest/v1',
      ]) {
        expect(
          () => SupabaseConfig(
            url: url,
            publishableKey: 'sb_publishable_ficticio',
          ).validate(),
          throwsFormatException,
        );
      }
    },
  );
}
