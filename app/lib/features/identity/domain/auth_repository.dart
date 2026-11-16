class IdentitySession {
  const IdentitySession({
    required this.userId,
    required this.email,
    this.recovery = false,
  });
  final String userId;
  final String email;
  final bool recovery;
}

abstract interface class AuthRepository {
  IdentitySession? get currentSession;
  Stream<IdentitySession?> get sessions;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> sendRecovery(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
}

bool validEmail(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
bool validPassword(String password) =>
    password.length >= 12 && password.length <= 128;
