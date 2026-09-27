import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../domain/plan.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../shell/shell_view_model.dart';

/// Disclosure/selection state that only the Today screen cares about.
class TodayUi {
  const TodayUi({
    this.whyOpen = false,
    this.laterOpen = false,
    this.reviewOpen = false,
    this.checkInOpen = false,
    this.focus,
    this.pIdx = 0,
    this.editing,
  });
  final String? focus, editing;
  final bool whyOpen, laterOpen, reviewOpen, checkInOpen;
  final int pIdx;

  TodayUi copyWith({bool? whyOpen, bool? laterOpen, bool? reviewOpen, bool? checkInOpen, String? Function()? focus, int? pIdx, String? Function()? editing}) => TodayUi(
        whyOpen: whyOpen ?? this.whyOpen,
        laterOpen: laterOpen ?? this.laterOpen,
        reviewOpen: reviewOpen ?? this.reviewOpen,
        checkInOpen: checkInOpen ?? this.checkInOpen,
        focus: focus != null ? focus() : this.focus,
        pIdx: pIdx ?? this.pIdx,
        editing: editing != null ? editing() : this.editing,
      );
}

class TodayState {
  const TodayState({
    required this.ui,
    required this.now,
    required this.name,
    required this.plan,
    required this.pending,
    required this.pulse,
    required this.pulseDone,
    required this.streak,
  });
  final TodayUi ui;
  final DateTime now;
  final String name;
  final List<PlanItem> plan;
  final List<Pending> pending;
  final Map<String, String> pulse;
  final bool pulseDone;
  final int streak;

  String get firstName => name.trim().isEmpty ? 'there' : name.trim().split(' ').first;
  String get initial => firstName == 'there' ? 'U' : firstName[0].toUpperCase();
  String get greeting => now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');
  String get dateLabel => '${weekdays[now.weekday - 1]} ${now.day}'.toUpperCase();

  PlanItem? get hero => plan.where((p) => p.s.id == ui.focus).firstOrNull ?? plan.firstOrNull;
  List<PlanItem> get more => plan.where((p) => p != hero).toList();

  /// Step progress: check in → your day → review.
  List<bool> get steps => [pulseDone, plan.any((p) => p.done), pending.isEmpty];

  bool get checkInExpanded => !pulseDone || ui.checkInOpen;
  int get pendingIndex => pending.isEmpty ? 0 : ui.pIdx % pending.length;
  Pending? get currentPending => pending.isEmpty ? null : pending[pendingIndex];

  String get checkInSubtitle {
    if (!pulseDone) return '3 taps keep your streak';
    final ans = [
      if (pulse['sleep'] != null) '${pulse['sleep']} sleep',
      if (pulse['energy'] != null) 'energy ${pulse['energy']}',
      if (pulse['sound'] != null) pulse['sound']!.toLowerCase(),
    ].join(' · ');
    return ans.isEmpty ? 'Done for today' : ans[0].toUpperCase() + ans.substring(1);
  }
}

/// Today's UI state on its own provider: it survives data changes and tab
/// switches, and resets whenever the signed-in account changes.
class _TodayUiController extends Notifier<TodayUi> {
  @override
  TodayUi build() {
    ref.watch(sessionProvider.select((s) => s.user));
    return const TodayUi();
  }

  void set(TodayUi ui) => state = ui;
}

final _todayUiProvider = NotifierProvider<_TodayUiController, TodayUi>(_TodayUiController.new);

class TodayViewModel extends Notifier<TodayState> {
  @override
  TodayState build() {
    final a = ref.watch(accountProvider);
    final now = ref.watch(clockProvider)();
    return TodayState(
      ui: ref.watch(_todayUiProvider),
      now: now,
      name: a.name,
      plan: ref.watch(planProvider),
      pending: ref.watch(pendingVisibleProvider),
      pulse: a.pulse,
      pulseDone: a.pulseDoneOn(now),
      streak: a.streak,
    );
  }

  AccountController get _account => ref.read(accountProvider.notifier);

  void _ui(TodayUi ui) => ref.read(_todayUiProvider.notifier).set(ui);

  // disclosure
  void toggleWhy() => _ui(state.ui.copyWith(whyOpen: !state.ui.whyOpen));
  void toggleLater() => _ui(state.ui.copyWith(laterOpen: !state.ui.laterOpen));
  void toggleReview() => _ui(state.ui.copyWith(reviewOpen: !state.ui.reviewOpen));
  void toggleCheckIn() => _ui(state.ui.copyWith(checkInOpen: !state.ui.checkInOpen));

  // plan
  void focus(PlanItem p) => _ui(state.ui.copyWith(focus: () => p.s.id, whyOpen: false));
  void start(PlanItem p) {
    _ui(state.ui.copyWith(whyOpen: false));
    _account.startSuggestion(p);
  }

  void skip(PlanItem p) {
    _ui(state.ui.copyWith(whyOpen: false, focus: () => state.ui.focus == p.s.id ? null : state.ui.focus));
    _account.skipSuggestion(p);
  }

  void notTrue(String memoryId) => _account.forget(memoryId);
  void openQuizzes() => ref.read(shellViewModelProvider.notifier).goTab('you');

  // check-in
  void setPulse(String k, String v) => _account.setPulse(k, v);

  // review
  void nextPending() => _ui(state.ui.copyWith(pIdx: state.ui.pIdx + 1, editing: () => null));
  void startEdit(Pending p) => _ui(state.ui.copyWith(editing: () => p.id));
  void cancelEdit() => _ui(state.ui.copyWith(editing: () => null));

  void keep(Pending p, [String? edited]) {
    _ui(state.ui.copyWith(editing: () => null));
    final t = edited?.trim();
    _account.keep(p, t == null || t.isEmpty || t == p.text ? null : t);
  }

  void reject(Pending p) => _account.reject(p);
}

final todayViewModelProvider = NotifierProvider<TodayViewModel, TodayState>(TodayViewModel.new);
