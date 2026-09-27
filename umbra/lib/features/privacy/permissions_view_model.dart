import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';

/// One learning source (a–e) as shown in onboarding and Privacy.
class MechRowState {
  const MechRowState({required this.key, required this.def, required this.on, required this.count});
  final String key;
  final Src def;
  final bool on;

  /// Memories that came from this source.
  final int count;

  bool get locked => key == 'explicit';
  String get rule => locked ? 'Saves directly' : (on ? 'Asks first' : 'Off');
}

/// Learning permissions shared by onboarding and the Privacy tab.
class PermissionsViewModel extends Notifier<List<MechRowState>> {
  @override
  List<MechRowState> build() {
    final a = ref.watch(accountProvider);
    return [
      for (final k in mechOrder) MechRowState(key: k, def: src[k]!, on: a.mech[k] ?? false, count: a.count((m) => m.source == k)),
    ];
  }

  void toggle(String k) => ref.read(accountProvider.notifier).toggleMech(k);

  void forget(String k) => ref.read(accountProvider.notifier).forgetBySource(k);
}

final permissionsViewModelProvider = NotifierProvider<PermissionsViewModel, List<MechRowState>>(PermissionsViewModel.new);
