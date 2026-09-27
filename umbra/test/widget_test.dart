import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umbra/data/backend.dart';
import 'package:umbra/data/repositories/account_repository.dart';
import 'package:umbra/data/repositories/auth_repository.dart';
import 'package:umbra/domain/rules.dart';
import 'package:umbra/features/today/today_view_model.dart';
import 'package:umbra/state/account_controller.dart';
import 'package:umbra/state/providers.dart';
import 'package:umbra/state/session_controller.dart';
import 'package:umbra/state/toast_controller.dart';

/// Model + ViewModel tests, no widgets.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      backendProvider.overrideWithValue(Backend(auth: AuthRepository(prefs), store: AccountRepository(prefs))),
      clockProvider.overrideWithValue(() => DateTime(2026, 9, 24, 9, 41)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('sign up, onboard and persist', () async {
    final c = makeContainer();
    final session = c.read(sessionProvider.notifier);
    expect(c.read(screenProvider), Screen.auth);
    expect(await session.signUp(name: 'Ada', email: 'bad', password: 'secret1'), 'Enter a valid email');
    expect(await session.signUp(name: 'Ada', email: 'ada@example.com', password: 'secret1'), isNull);
    expect(c.read(screenProvider), Screen.onboarding);

    final account = c.read(accountProvider.notifier);
    account.setRole('Engineer');
    account.obNext();
    account.obNext();
    expect(account.obNext(), isTrue);
    expect(c.read(screenProvider), Screen.app);
    expect(c.read(accountProvider).mem.map((m) => m.id), containsAll(['i_name', 'i_role']));
    account.tell('Allergic to peanuts', 'identity');
    await account.flush();

    // A fresh container restores the session (splash first) and data from disk.
    final again = makeContainer();
    expect(again.read(screenProvider), Screen.loading);
    await pumpEventQueue();
    expect(again.read(sessionProvider).user?.email, 'ada@example.com');
    expect(again.read(accountProvider).mem.length, 3);
    await again.read(accountProvider.notifier).signOut();
    expect(again.read(screenProvider), Screen.auth);
    expect(await again.read(sessionProvider.notifier).signIn(email: 'ada@example.com', password: 'wrong'), isNotNull);
    expect(await again.read(sessionProvider.notifier).signIn(email: 'ada@example.com', password: 'secret1'), isNull);
    expect(again.read(accountProvider).mem.length, 3);
  });

  test('demo account: forget + undo, keep pending, check-in', () {
    final c = makeContainer();
    c.read(sessionProvider.notifier).tryDemo();
    expect(c.read(screenProvider), Screen.app);
    expect(c.read(planProvider), isNotEmpty);

    final account = c.read(accountProvider.notifier);
    final n = c.read(accountProvider).mem.length;
    account.forget(c.read(accountProvider).mem.first.id);
    expect(c.read(accountProvider).mem.length, n - 1);
    c.read(toastProvider.notifier).undo();
    expect(c.read(accountProvider).mem.length, n);

    final p = c.read(pendingVisibleProvider).first;
    c.read(todayViewModelProvider.notifier).keep(p);
    expect(c.read(accountProvider).mem.length, n + 1);
    expect(c.read(accountProvider).pending.any((x) => x.id == p.id), isFalse);

    final streak = c.read(accountProvider).streak;
    final today = c.read(todayViewModelProvider.notifier);
    today.setPulse('sleep', 'Great');
    today.setPulse('energy', '4');
    today.setPulse('sound', 'Calm');
    expect(c.read(todayViewModelProvider).pulseDone, isTrue);
    expect(c.read(accountProvider).streak, streak + 1);
  });

  test('turning a source off hides its pending signals', () {
    final c = makeContainer();
    c.read(sessionProvider.notifier).tryDemo();
    final before = c.read(pendingVisibleProvider).length;
    c.read(accountProvider.notifier).toggleMech('ambient');
    final after = c.read(pendingVisibleProvider);
    expect(after.length, lessThan(before));
    expect(after.every((p) => p.source != 'ambient'), isTrue);
    expect(c.read(accountProvider).allowed('ambient', null), isFalse);
  });

  test('today UI state survives account changes but resets on sign-out', () async {
    final c = makeContainer();
    c.read(sessionProvider.notifier).tryDemo();
    final vm = c.read(todayViewModelProvider.notifier);
    vm.toggleReview();
    c.read(accountProvider.notifier).toggleHealthExport();
    expect(c.read(todayViewModelProvider).ui.reviewOpen, isTrue);
    await c.read(accountProvider.notifier).signOut();
    c.read(sessionProvider.notifier).tryDemo();
    expect(c.read(todayViewModelProvider).ui.reviewOpen, isFalse);
  });
}
