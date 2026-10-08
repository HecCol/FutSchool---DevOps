abstract class AuthService {
  Stream<bool> get sessionChanges;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String fullName, String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
