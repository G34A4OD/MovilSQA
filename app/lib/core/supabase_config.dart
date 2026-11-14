class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});
  final String url;
  final String publishableKey;

  static const fromEnvironment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
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
