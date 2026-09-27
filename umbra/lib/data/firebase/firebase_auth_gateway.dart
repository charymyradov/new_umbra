import 'package:firebase_auth/firebase_auth.dart';

import '../backend.dart';

/// Umbra accounts in Firebase Auth (email + password). The profile itself
/// (`users/{uid}`) is written by the account store together with the rest of
/// the account, so sign-up makes no Firestore write of its own.
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth);
  final FirebaseAuth _auth;

  /// Waits until Firebase has restored the previous session (if any).
  Future<void> restore() => _auth.authStateChanges().first;

  static AuthUser _user(User u, [String? name]) => AuthUser(uid: u.uid, email: u.email ?? '', name: name ?? u.displayName ?? '');

  @override
  AuthUser? get current {
    final u = _auth.currentUser;
    // A session opened with a custom token belongs to a connected app, not to Umbra.
    return u == null || u.isAnonymous || u.email == null ? null : _user(u);
  }

  @override
  Future<AuthUser> signUp({required String name, required String email, required String password}) async {
    final n = name.trim();
    if (n.isEmpty) throw const AuthFailure('Add your name');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final u = cred.user!;
      try {
        await u.updateDisplayName(n);
      } on FirebaseAuthException {
        // The name is also saved in users/{uid}; the Auth copy is only a convenience.
      }
      return _user(u, n);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _user(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  static String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Email or password doesn’t match',
        'email-already-in-use' => 'Account exists — sign in instead',
        'weak-password' => 'Password needs 6+ characters',
        'invalid-email' => 'Enter a valid email',
        'network-request-failed' => 'Can’t connect. Check your internet.',
        'too-many-requests' => 'Too many tries. Wait a moment.',
        'user-disabled' => 'This account has been disabled',
        'operation-not-allowed' => 'Email sign-in is turned off for this project',
        _ => e.message ?? 'Something went wrong. Try again.',
      };
}
