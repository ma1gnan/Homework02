import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Current signed-in user
  User? get currentUser => _auth.currentUser;

  // Stable stream of authentication changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register a new user
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in an existing user
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
