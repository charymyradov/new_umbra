import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backend.dart';
import '../data/models.dart';
import '../data/repositories/account_repository.dart';
import '../domain/plan.dart';
import '../domain/rules.dart';
import 'account_controller.dart';
import 'connect_controller.dart';
import 'session_controller.dart';

/// Overridden in `main()` (and in tests) with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('Override sharedPreferencesProvider'));

/// Firebase on Android/iOS, local elsewhere. Overridden in `main()` and in tests.
final backendProvider = Provider<Backend>((_) => throw UnimplementedError('Override backendProvider'));

/// The demo account never leaves the device.
final demoStoreProvider = Provider<AccountStore>((ref) => AccountRepository(ref.watch(sharedPreferencesProvider)));

/// Injectable clock so tests can pin "now".
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

enum Screen { loading, auth, onboarding, connect, app }

final screenProvider = Provider<Screen>((ref) {
  final s = ref.watch(sessionProvider);
  if (s.user == null) return s.restoring ? Screen.loading : Screen.auth;
  if (!ref.watch(accountProvider.select((a) => a.onboarded))) return Screen.onboarding;
  // A "Continue with Umbra" request waits until the person is signed in and set up.
  return ref.watch(connectProvider.select((c) => c.request != null)) ? Screen.connect : Screen.app;
});

/// Today's plan, recomputed only when the account changes.
final planProvider = Provider<List<PlanItem>>((ref) => buildPlan(ref.watch(accountProvider)));

/// Signals waiting for the person's OK, filtered by current permissions.
final pendingVisibleProvider = Provider<List<Pending>>((ref) => ref.watch(accountProvider).pendingVisible);
