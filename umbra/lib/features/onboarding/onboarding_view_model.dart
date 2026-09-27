import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/account_controller.dart';
import '../shell/shell_view_model.dart';

class OnboardingState {
  const OnboardingState({required this.step, required this.name, required this.role, required this.chosenDomains, required this.dir});

  /// 1 = who are you, 2 = domains, 3 = learning permissions.
  final int step;
  final String name, role;
  final List<String> chosenDomains;

  /// Slide direction of the last step change.
  final int dir;

  bool get canBack => step > 1;
  String get nextLabel => const ['Get started', 'Continue', 'Continue', 'Start'][step.clamp(0, 3)];
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final a = ref.watch(accountProvider);
    return OnboardingState(step: a.ob, name: a.name, role: a.role, chosenDomains: a.chosenDomains, dir: stateOrNull?.dir ?? 1);
  }

  AccountController get _account => ref.read(accountProvider.notifier);

  void setName(String v) => _account.setName(v);
  void setRole(String v) => _account.setRole(v);
  void toggleDomain(String id) => _account.toggleDomain(id);

  void back() {
    state = OnboardingState(step: state.step, name: state.name, role: state.role, chosenDomains: state.chosenDomains, dir: -1);
    _account.obBack();
  }

  void next() {
    state = OnboardingState(step: state.step, name: state.name, role: state.role, chosenDomains: state.chosenDomains, dir: 1);
    // Finishing lands on the You tab so the first quiz is one tap away.
    if (_account.obNext()) ref.read(shellViewModelProvider.notifier).goTab('you', animateFromOrder: false);
  }
}

final onboardingViewModelProvider = NotifierProvider.autoDispose<OnboardingViewModel, OnboardingState>(OnboardingViewModel.new);
