import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The SDK persists the whole session JSON, including refresh tokens.
/// Keep that JSON and PKCE verifiers in platform protected storage.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this.storage, {required this.projectHost});
  final FlutterSecureStorage storage;
  final String projectHost;
  String get _key => 'nido.$projectHost.session';

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() => storage.containsKey(key: _key);
  @override
  Future<String?> accessToken() => storage.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => storage.delete(key: _key);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage(this.storage, {required this.projectHost});
  final FlutterSecureStorage storage;
  final String projectHost;
  String _key(String key) => 'nido.$projectHost.pkce.$key';
  @override
  Future<String?> getItem({required String key}) =>
      storage.read(key: _key(key));
  @override
  Future<void> setItem({required String key, required String value}) =>
      storage.write(key: _key(key), value: value);
  @override
  Future<void> removeItem({required String key}) =>
      storage.delete(key: _key(key));
}

const nidoSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  ),
);
