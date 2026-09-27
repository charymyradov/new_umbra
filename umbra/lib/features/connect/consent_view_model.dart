import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/connect/external_apps.dart';
import '../../state/connect_controller.dart';
import '../../state/session_controller.dart';

class ConsentState {
  const ConsentState({required this.app, required this.scopes, required this.email, required this.busy, this.error});
  final ExternalAppDef app;

  /// What will be shared, worded for the person.
  final List<String> scopes;
  final String email;
  final bool busy;
  final String? error;
}

class ConsentViewModel extends Notifier<ConsentState?> {
  @override
  ConsentState? build() {
    final c = ref.watch(connectProvider);
    final r = c.request;
    if (r == null) return null;
    return ConsentState(
      app: r.app,
      scopes: [for (final s in r.scopes) kScopeCatalog[s]!],
      email: ref.watch(sessionProvider.select((s) => s.user?.email)) ?? '',
      busy: c.busy,
      error: c.error,
    );
  }

  void allow() => ref.read(connectProvider.notifier).allow();
  void deny() => ref.read(connectProvider.notifier).deny();
}

final consentViewModelProvider = NotifierProvider.autoDispose<ConsentViewModel, ConsentState?>(ConsentViewModel.new);
