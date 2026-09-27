import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/auth/auth_view.dart';
import '../features/connect/consent_view.dart';
import '../features/onboarding/onboarding_view.dart';
import '../features/shell/shell_view.dart';
import '../state/account_controller.dart';
import '../state/connect_controller.dart';
import '../state/providers.dart';
import '../widgets/toast_layer.dart';

class UmbraApp extends ConsumerStatefulWidget {
  const UmbraApp({super.key});

  @override
  ConsumerState<UmbraApp> createState() => _UmbraAppState();
}

class _UmbraAppState extends ConsumerState<UmbraApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start listening for "Continue with Umbra" links right away, signed in or not.
    ref.read(connectProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final account = ref.read(accountProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        account.refreshDay();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        account.flush();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: C.paper),
      child: MaterialApp(
        title: 'Umbra',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => _DeviceFrame(child: Stack(children: [child!, const ToastLayer()])),
        home: const _Root(),
      ),
    );
  }
}

/// On tablets, desktop and web the app is shown in a phone-sized column over the desk color.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= 560) return child;
    final h = math.min(mq.size.height - 48, 900.0);
    const w = 420.0;
    return ColoredBox(
      color: C.desk,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: C.inkDeep,
            borderRadius: BorderRadius.circular(56),
            boxShadow: const [BoxShadow(offset: Offset(0, 40), blurRadius: 80, spreadRadius: -30, color: Color(0x732B2620))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(46),
            child: SizedBox(
              width: w,
              height: h,
              child: MediaQuery(
                data: mq.copyWith(size: Size(w, h), padding: const EdgeInsets.only(top: 18, bottom: 12), viewPadding: const EdgeInsets.only(top: 18, bottom: 12)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(screenProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: easeOutSoft,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(anim), child: child),
      ),
      child: switch (screen) {
        Screen.loading => const _Splash(key: ValueKey('loading')),
        Screen.auth => const AuthView(key: ValueKey('auth')),
        Screen.connect => const ConsentView(key: ValueKey('connect')),
        Screen.onboarding => const OnboardingView(key: ValueKey('ob')),
        Screen.app => const ShellView(key: ValueKey('app')),
      },
    );
  }
}

/// Shown while the last session's account is loaded.
class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(color: C.paper, child: Center(child: UmbraMark(size: 88)));
}
