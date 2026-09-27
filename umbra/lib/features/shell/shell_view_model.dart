import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../state/session_controller.dart';

const tabOrder = ['today', 'memory', 'you', 'sources', 'privacy', 'setir'];

class ShellState {
  const ShellState({this.tab = 'today', this.dir = 0});
  final String tab;

  /// Entrance direction: 1 slides in from the right, -1 from the left, 0 rises.
  final int dir;

  /// The nav highlights Privacy while its Sources sub-page is open.
  bool isOn(String id) => tab == id || (id == 'privacy' && tab == 'sources');
}

/// Which tab is showing. Resets to Today whenever the signed-in account changes.
class ShellViewModel extends Notifier<ShellState> {
  @override
  ShellState build() {
    ref.watch(sessionProvider.select((s) => s.user));
    return const ShellState();
  }

  void goTab(String id, {bool animateFromOrder = true}) {
    if (id == state.tab) return;
    final dir = !animateFromOrder ? 0 : (tabOrder.indexOf(id) >= tabOrder.indexOf(state.tab) ? 1 : -1);
    state = ShellState(tab: id, dir: dir);
  }
}

final shellViewModelProvider = NotifierProvider<ShellViewModel, ShellState>(ShellViewModel.new);

/// Dot on the Today tab when something waits for review and Today isn't showing.
final todayBadgeProvider = Provider<bool>(
  (ref) => ref.watch(shellViewModelProvider.select((s) => s.tab != 'today')) && ref.watch(pendingVisibleProvider).isNotEmpty,
);
