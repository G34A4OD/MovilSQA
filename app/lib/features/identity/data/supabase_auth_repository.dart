import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  static const redirect = 'nido://auth/callback';
  IdentitySession? _session(Session? s, {bool recovery = false}) => s == null
      ? null
      : IdentitySession(
          userId: s.user.id,
          email: s.user.email ?? '',
          recovery: recovery,
        );
  @override
  IdentitySession? get currentSession => _session(client.auth.currentSession);
  @override
  Stream<IdentitySession?> get sessions => client.auth.onAuthStateChange.map(
    (state) => _session(
      state.session,
      recovery: state.event == AuthChangeEvent.passwordRecovery,
    ),
  );
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String email, String password) async {
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: redirect,
    );
  }

  @override
  Future<void> sendRecovery(String email) =>
      client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirect);
  @override
  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
