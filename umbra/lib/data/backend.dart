/// What the app needs from an account system and from the place account data lives.
///
/// Two implementations exist: Firebase (Auth + Firestore) on Android/iOS, and the
/// local `shared_preferences` one used for the demo account, on the web and in tests.
library;

import 'connect/auth_worker.dart';
import 'models.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.email, this.name = ''});
  final String uid, email, name;
}

/// A sign-in/sign-up problem worded for the person.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthGateway {
  /// The account restored from the last run, if any.
  AuthUser? get current;

  /// Throws [AuthFailure].
  Future<AuthUser> signUp({required String name, required String email, required String password});

  /// Throws [AuthFailure].
  Future<AuthUser> signIn({required String email, required String password});

  Future<void> signOut();

  /// A token the auth worker accepts; null for local accounts.
  Future<String?> idToken();
}

abstract interface class AccountStore {
  /// Reads the account into memory. Null when it was never saved.
  Future<AccountData?> load(String uid);

  /// What [load] or the last [save] left in memory.
  AccountData? peek(String uid);

  /// Persists [data] as one write. Completes when that write is committed.
  Future<void> save(String uid, AccountData data);
}

class Backend {
  const Backend({required this.auth, required this.store, this.worker});
  final AuthGateway auth;
  final AccountStore store;

  /// Only Firebase accounts can sign in to other apps ("Continue with Umbra").
  final AuthWorker? worker;
}
