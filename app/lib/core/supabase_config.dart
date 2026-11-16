import 'package:flutter/foundation.dart';

class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.publishableKey,
    this.localTest = false,
  });
  final String url;
  final String publishableKey;
  final bool localTest;

  static const fromEnvironment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    localTest: bool.fromEnvironment('SUPABASE_LOCAL_TEST'),
  );

  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  void validate() {
    final uri = Uri.tryParse(url);
    final localDebug =
        kDebugMode &&
        localTest &&
        uri?.scheme == 'http' &&
        uri?.host == '127.0.0.1' &&
        uri?.port == 54321;
    if (uri == null ||
        (uri.scheme != 'https' && !localDebug) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !publishableKey.startsWith('sb_publishable_')) {
      throw const FormatException(
        'Configura URL HTTPS y clave publishable de Supabase.',
      );
    }
  }
}
