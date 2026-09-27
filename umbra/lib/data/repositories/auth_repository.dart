import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend.dart';

/// Local accounts (salted SHA-256) and the signed-in session, kept in [SharedPreferences].
///
/// Used where Firebase isn't available (web, tests). The account id is the email.
class AuthRepository implements AuthGateway {
  AuthRepository(this._prefs, {this.clock = DateTime.now});

  static const _kAccounts = 'umbra.accounts.v3';
  static const _kSession = 'umbra.session.v3';
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final SharedPreferences _prefs;
  final DateTime Function() clock;

  Map<String, Map<String, Object?>> _accounts() {
    try {
      final raw = _prefs.getString(_kAccounts);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, Map<String, Object?>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  void _save(Map<String, Map<String, Object?>> a) => _prefs.setString(_kAccounts, jsonEncode(a));

  static String _salt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String _hash(String salt, String pw) => sha256.convert(utf8.encode('$salt:$pw')).toString();

  static String normalize(String email) => email.trim().toLowerCase();

  AuthUser _user(String email) => AuthUser(uid: email, email: email, name: _accounts()[email]?['name'] as String? ?? '');

  @override
  AuthUser? get current {
    final e = _prefs.getString(_kSession);
    return e != null && _accounts().containsKey(e) ? _user(e) : null;
  }

  @override
  Future<AuthUser> signUp({required String name, required String email, required String password}) async {
    final e = normalize(email), n = name.trim();
    if (n.isEmpty) throw const AuthFailure('Add your name');
    if (!_emailRe.hasMatch(e)) throw const AuthFailure('Enter a valid email');
    if (password.length < 6) throw const AuthFailure('Password needs 6+ characters');
    final a = _accounts();
    if (a.containsKey(e)) throw const AuthFailure('Account exists — sign in instead');
    final salt = _salt();
    a[e] = {'name': n, 'email': e, 'salt': salt, 'pw': _hash(salt, password), 'created': clock().toIso8601String()};
    _save(a);
    await _prefs.setString(_kSession, e);
    return _user(e);
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final e = normalize(email);
    final acc = _accounts()[e];
    if (acc == null || acc['pw'] != _hash(acc['salt'] as String? ?? '', password)) throw const AuthFailure('Email or password doesn’t match');
    await _prefs.setString(_kSession, e);
    return _user(e);
  }

  @override
  Future<void> signOut() => _prefs.remove(_kSession);

  @override
  Future<String?> idToken() async => null;
}
