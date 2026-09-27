import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/catalog.dart';
import '../../data/connect/external_apps.dart';
import '../../data/models.dart';
import '../../data/services/share_service.dart';
import '../../domain/export.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../../state/toast_controller.dart';
import '../shell/shell_view_model.dart';

final shareServiceProvider = Provider((_) => const ShareService());

class PrivacyState {
  const PrivacyState({
    required this.open,
    required this.now,
    required this.memories,
    required this.pending,
    required this.bySource,
    required this.byLayer,
    required this.mech,
    required this.liveConns,
    required this.healthExport,
    required this.log,
  });

  /// Expanded sections: learn, export, forget, recent.
  final Set<String> open;
  final DateTime now;
  final int memories, pending;
  final Map<String, int> bySource, byLayer;
  final Map<String, bool> mech;
  final List<Conn> liveConns;
  final bool healthExport;
  final List<LogEntry> log;

  int get mechOn => mechOrder.where((k) => mech[k] ?? false).length;
  bool get hasAnything => memories > 0 || pending > 0;
}

class PrivacyViewModel extends Notifier<PrivacyState> {
  @override
  PrivacyState build() {
    final a = ref.watch(accountProvider);
    return PrivacyState(
      open: stateOrNull?.open ?? const {},
      now: ref.watch(clockProvider)(),
      memories: a.mem.length,
      pending: a.pending.length,
      bySource: {for (final k in mechOrder) k: a.count((m) => m.source == k)},
      byLayer: {for (final l in layers) l.id: a.count((m) => m.layer == l.id)},
      mech: a.mech,
      liveConns: a.liveConns,
      healthExport: a.healthExport,
      log: a.log.take(8).toList(),
    );
  }

  AccountController get _account => ref.read(accountProvider.notifier);

  void toggleSection(String k) {
    final open = {...state.open};
    open.contains(k) ? open.remove(k) : open.add(k);
    state = PrivacyState(
      open: open,
      now: state.now,
      memories: state.memories,
      pending: state.pending,
      bySource: state.bySource,
      byLayer: state.byLayer,
      mech: state.mech,
      liveConns: state.liveConns,
      healthExport: state.healthExport,
      log: state.log,
    );
  }

  void toggleHealthExport() => _account.toggleHealthExport();
  void forgetLayer(String id) => _account.forgetLayer(id);
  void forgetAll() => _account.forgetAll();
  void openSources() => ref.read(shellViewModelProvider.notifier).goTab('sources');
  void signOut() => ref.read(accountProvider.notifier).signOut();

  /// Exports everything (health only if allowed) as JSON or a readable summary.
  Future<void> export({required bool json, Rect? origin}) async {
    final a = ref.read(accountProvider);
    final now = ref.read(clockProvider)();
    final name = json ? 'umbra-memory.json' : 'umbra-memory-summary.txt';
    final outcome = await ref.read(shareServiceProvider).shareFile(
          name: name,
          mimeType: json ? 'application/json' : 'text/plain',
          text: json ? exportJson(a, now) : exportText(a, now),
          origin: origin,
        );
    if (!ref.mounted) return;
    _account.logExport(json ? 'JSON' : 'summary');
    final toast = ref.read(toastProvider.notifier);
    switch (outcome) {
      case ShareOutcome.shared:
        toast.show('Exported $name');
      case ShareOutcome.copied:
        toast.show('${json ? 'JSON' : 'Summary'} copied to clipboard');
      case ShareOutcome.dismissed:
        break;
    }
  }
}

final privacyViewModelProvider = NotifierProvider.autoDispose<PrivacyViewModel, PrivacyState>(PrivacyViewModel.new);

class FolderSummary {
  const FolderSummary(this.folder, this.apps, this.live);
  final Folder folder;
  final List<Conn> apps;
  final Set<String> live;

  int get onCount => live.length;
}

/// An outside app signed in with the person's Umbra account.
class LinkedSummary {
  const LinkedSummary({required this.id, required this.name, required this.glyph, required this.shares, required this.since});
  final String id, name, glyph, since;

  /// What it can read, e.g. "Your name · Reading topics, times and formats".
  final String shares;
}

class SourcesState {
  const SourcesState({required this.liveConns, required this.folders, this.linked = const []});
  final List<Conn> liveConns;
  final List<FolderSummary> folders;
  final List<LinkedSummary> linked;

  String get stackLabel => liveConns.isEmpty ? 'Nothing connected' : (liveConns.length > 5 ? '+${liveConns.length - 5} more sharing' : 'Sharing with Umbra');
}

class SourcesViewModel extends Notifier<SourcesState> {
  @override
  SourcesState build() {
    final a = ref.watch(accountProvider);
    final live = a.liveConns;
    return SourcesState(
      liveConns: live,
      folders: [
        for (final f in folders)
          FolderSummary(f, conns.where((c) => c.folder == f.id).toList(), {for (final c in live.where((c) => c.folder == f.id)) c.id}),
      ],
      linked: [
        for (final MapEntry(key: id, value: l) in a.linked.entries)
          LinkedSummary(
            id: id,
            name: kExternalApps[id]?.name ?? id,
            glyph: kExternalApps[id]?.glyph ?? id[0].toUpperCase(),
            shares: [for (final s in l.scopes) kScopeCatalog[s] ?? s].join(' · '),
            since: fmtDate(l.since),
          ),
      ],
    );
  }

  void back() => ref.read(shellViewModelProvider.notifier).goTab('privacy');
  void disconnect(String appId) => ref.read(accountProvider.notifier).unlinkApp(appId);
}

final sourcesViewModelProvider = NotifierProvider.autoDispose<SourcesViewModel, SourcesState>(SourcesViewModel.new);
