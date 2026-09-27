import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/backend.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../domain/rules.dart';
import 'providers.dart';
import 'toast_controller.dart';

/// A signed-in account. The demo account lives only on this device.
class Session {
  const Session({required this.uid, required this.email, this.name = '', this.demo = false});
  final String uid, email, name;
  final bool demo;

  @override
  bool operator ==(Object other) => other is Session && other.uid == uid && other.demo == demo;

  @override
  int get hashCode => Object.hash(uid, demo);
}

class SessionState {
  const SessionState({this.user, this.restoring = false});
  final Session? user;

  /// The previous run's account is being loaded (splash screen).
  final bool restoring;
}

/// Who is signed in, and signing in/up/out.
class SessionController extends Notifier<SessionState> {
  static const _kDemo = 'umbra.demo.v1';
  static const demoEmail = 'demo@umbra.app';
  static const _demo = Session(uid: demoEmail, email: demoEmail, name: 'Maya', demo: true);

  Backend get _backend => ref.read(backendProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  DateTime get _now => ref.read(clockProvider)();

  @override
  SessionState build() {
    if (_prefs.getBool(_kDemo) ?? false) return const SessionState(user: _demo);
    final u = _backend.auth.current;
    if (u == null) return const SessionState();
    Future.microtask(() async {
      final err = await _open(u);
      if (err != null && ref.mounted) state = const SessionState();
    });
    return const SessionState(restoring: true);
  }

  /// Where [s]'s data is kept.
  AccountStore storeFor(Session s) => s.demo ? ref.read(demoStoreProvider) : _backend.store;

  /// Returns an error message, or null on success.
  Future<String?> signUp({required String name, required String email, required String password}) async {
    try {
      final u = await _backend.auth.signUp(name: name, email: email, password: password);
      final s = Session(uid: u.uid, email: u.email, name: u.name);
      final store = storeFor(s);
      await store.load(s.uid);
      // The profile, settings and default connections go out as one write.
      unawaited(store.save(s.uid, AccountData(name: name.trim(), connsOn: defaultConns)).catchError((Object _) {}));
      state = SessionState(user: s);
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      final u = await _backend.auth.signIn(email: email, password: password);
      final err = await _open(u);
      if (err != null) return err;
      final n = _backend.store.peek(u.uid)?.mem.length ?? 0;
      if (n > 0) ref.read(toastProvider.notifier).show('Welcome back — ${plural(n, 'memory', 'memories')} restored');
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  /// Loads [u]'s data, then opens the session. Returns an error message on failure.
  Future<String?> _open(AuthUser u) async {
    final s = Session(uid: u.uid, email: u.email, name: u.name);
    try {
      await storeFor(s).load(s.uid);
    } catch (_) {
      await _backend.auth.signOut();
      return 'Couldn’t load your memory. Check your connection.';
    }
    if (ref.mounted) state = SessionState(user: s);
    return null;
  }

  void tryDemo() {
    final store = ref.read(demoStoreProvider);
    if (!(store.peek(demoEmail)?.onboarded ?? false)) store.save(demoEmail, _demoAccount(_now));
    _prefs.setBool(_kDemo, true);
    state = const SessionState(user: _demo);
  }

  /// Ends the session. Call [AccountController.signOut] instead, which first
  /// writes what's unsaved ([saved]) so nothing is lost and no write goes out signed out.
  Future<void> signOut({Future<bool>? saved}) async {
    final s = state.user;
    if (s == null) return;
    state = const SessionState();
    if (s.demo) {
      await _prefs.remove(_kDemo);
      return;
    }
    await saved?.timeout(const Duration(seconds: 5), onTimeout: () => false);
    await _backend.auth.signOut();
  }

  static AccountData _demoAccount(DateTime now) {
    const topics = ['Cognitive science', 'Design'];
    final s = demoSeed(now: now, name: 'Maya', role: 'Product designer', topics: topics);
    final base = AccountData(
      onboarded: true,
      name: 'Maya',
      role: 'Product designer',
      topics: topics,
      times: const ['Evening'],
      formats: const ['print', 'audio'],
      connsOn: defaultConns,
      pending: s.pending,
      log: s.log,
      questsDone: const {'reading'},
      xp: 310,
      streak: 5,
      lastCheckIn: now.subtract(const Duration(days: 1)),
      suggDay: dayOf(now),
    );
    return base.copyWith(mem: s.mem.where((m) => base.allowed(m.source, m.conn)).toList());
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
