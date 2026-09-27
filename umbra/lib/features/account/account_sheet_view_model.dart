import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../../state/session_controller.dart';

class AccountSummary {
  const AccountSummary({required this.name, required this.email, required this.memories, required this.liveSources});
  final String name, email;
  final int memories, liveSources;

  String get displayName => name.trim().isEmpty ? 'You' : name.trim();
}

class AccountSheetViewModel extends Notifier<AccountSummary> {
  @override
  AccountSummary build() {
    final a = ref.watch(accountProvider);
    return AccountSummary(
      name: a.name,
      email: ref.watch(sessionProvider.select((s) => s.user?.email)) ?? 'Not signed in',
      memories: a.mem.length,
      liveSources: a.liveConns.length,
    );
  }

  void signOut() => ref.read(accountProvider.notifier).signOut();
}

final accountSheetViewModelProvider = NotifierProvider.autoDispose<AccountSheetViewModel, AccountSummary>(AccountSheetViewModel.new);
