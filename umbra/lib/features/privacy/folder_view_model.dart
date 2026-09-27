import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/catalog.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';

/// One connected app inside a folder.
class AppRowState {
  const AppRowState({required this.conn, required this.on, required this.mechOn, required this.memories});
  final Conn conn;
  final bool on, mechOn;
  final int memories;

  bool get live => on && mechOn;
  Src get mechanism => src[conn.mech]!;

  String get status {
    if (!mechOn) return 'Paused';
    if (!on) return 'Not connected';
    return memories > 0 ? '${plural(memories, 'memory', 'memories')} · ${conn.synced}' : 'Synced ${conn.synced}';
  }
}

class FolderState {
  const FolderState({required this.folder, required this.apps, this.selected});
  final Folder folder;
  final List<AppRowState> apps;

  /// App whose detail page is open, or null for the list.
  final String? selected;

  AppRowState? get app => apps.where((a) => a.conn.id == selected).firstOrNull;
}

class FolderViewModel extends Notifier<FolderState> {
  FolderViewModel(this.folderId);
  final String folderId;

  @override
  FolderState build() {
    final a = ref.watch(accountProvider);
    return FolderState(
      folder: folders.firstWhere((f) => f.id == folderId),
      apps: [
        for (final c in conns.where((c) => c.folder == folderId))
          AppRowState(conn: c, on: a.connsOn[c.id] ?? false, mechOn: a.mech[c.mech] ?? false, memories: a.count((m) => m.conn == c.id)),
      ],
      selected: stateOrNull?.selected,
    );
  }

  AccountController get _account => ref.read(accountProvider.notifier);

  void open(String id) => state = FolderState(folder: state.folder, apps: state.apps, selected: id);
  void back() => state = FolderState(folder: state.folder, apps: state.apps);
  void toggle(String id) => _account.toggleConn(id);
  void forgetApp(String id) => _account.removeConn(id);
  void enableMechanism(String k) => _account.enableMech(k);
}

final folderViewModelProvider = NotifierProvider.autoDispose.family<FolderViewModel, FolderState, String>(FolderViewModel.new);
