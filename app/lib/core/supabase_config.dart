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

  // These values identify the shared test project. Auth and RLS grant access.
  static const nidoDev = SupabaseConfig(
    url: 'https://dcwfnnttrxbtavshrbfj.supabase.co',
    publishableKey: 'sb_publishable_Olzx18t0CgrhwTX1UgyiOg_TMruRvwR',
  );

  static const _hasUrl = bool.hasEnvironment('SUPABASE_URL');
  static const _hasKey = bool.hasEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _localTest = bool.fromEnvironment('SUPABASE_LOCAL_TEST');

  // Treat overrides as a pair. In particular, a local test must never
  // silently fall back to the hosted project when its values are missing.
  static const forBuild = _hasUrl || _hasKey || _localTest
      ? fromEnvironment
      : nidoDev;

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
