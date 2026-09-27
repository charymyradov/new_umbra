import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umbra/app/app.dart';
import 'package:umbra/data/backend.dart';
import 'package:umbra/data/repositories/account_repository.dart';
import 'package:umbra/data/repositories/auth_repository.dart';
import 'package:umbra/features/quiz/quiz_view.dart';
import 'package:umbra/features/shell/shell_view_model.dart';
import 'package:umbra/state/account_controller.dart';
import 'package:umbra/state/providers.dart';
import 'package:umbra/state/session_controller.dart';

/// Renders every screen of the demo account and fails on any layout/build exception.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpApp(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      backendProvider.overrideWithValue(Backend(auth: AuthRepository(prefs), store: AccountRepository(prefs))),
      clockProvider.overrideWithValue(() => DateTime(2026, 9, 24, 9, 41)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const UmbraApp()));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(390, 844), Size(340, 700)]) {
    testWidgets('demo tabs render at ${size.width.toInt()}w', (tester) async {
      final c = await pumpApp(tester, size: size);
      expect(find.text('Explore the demo account'), findsOneWidget);
      c.read(sessionProvider.notifier).tryDemo();
      await settle(tester);
      expect(find.textContaining('Maya'), findsWidgets);

      // Expand the Today sections.
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Later today'), 200, scrollable: list);
      await tester.drag(list, const Offset(0, -200));
      await settle(tester);
      await tester.tap(find.text('Later today'));
      await settle(tester);
      await tester.scrollUntilVisible(find.text('Is this you?'), 200, scrollable: list);
      await tester.drag(list, const Offset(0, -250));
      await settle(tester);
      await tester.tap(find.text('Is this you?'));
      await settle(tester);
      expect(find.text('Yes, that’s me'), findsOneWidget);

      for (final tab in tabOrder) {
        c.read(shellViewModelProvider.notifier).goTab(tab);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'tab $tab');
      }

      c.read(shellViewModelProvider.notifier).goTab('memory');
      await settle(tester);
      await tester.tap(find.text('Who you are'));
      await settle(tester);
      final club = find.textContaining('Monthly book club');
      await tester.ensureVisible(club);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await settle(tester);
      await tester.tap(club);
      await settle(tester);
      expect(find.text('How I know this'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });
  }

  testWidgets('quiz flow renders every question type', (tester) async {
    final c = await pumpApp(tester);
    c.read(sessionProvider.notifier).tryDemo();
    await settle(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    openQuiz(ctx, 'music');
    await settle(tester);
    await tester.tap(find.text('Start'));
    await settle(tester);
    // multi → duo → swipe ×4 → multi → scale → text
    await tester.tap(find.text('Jazz'));
    await tester.pump();
    await tester.tap(find.text('Continue · 1'));
    await settle(tester);
    await tester.tap(find.text('Instrumental'));
    await settle(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('That’s me'));
      await settle(tester);
    }
    await tester.tap(find.text('Focus'));
    await tester.pump();
    await tester.tap(find.text('Continue · 1'));
    await settle(tester);
    await tester.tap(find.text('Mellow'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Nina Simone');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('What I’ll remember'), findsOneWidget);
    await tester.tap(find.textContaining('to memory'));
    await settle(tester);
    expect(c.read(accountProvider).mem.any((m) => m.id == 'q_music_artist' && m.text == 'Never tires of Nina Simone.'), isTrue);
    expect(c.read(shellViewModelProvider).tab, 'you');
    await tester.pump(const Duration(seconds: 7));
  });
}
