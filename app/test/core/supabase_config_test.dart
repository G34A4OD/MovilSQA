import 'package:app/core/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
