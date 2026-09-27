import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

/// A memory row with everything the list needs precomputed.
class MemoryItem {
  const MemoryItem({required this.m, required this.meta, required this.stale, required this.daysLeft});
  final Memory m;
  final String meta;
  final bool stale;
  final int daysLeft;
}

class LayerSection {
  const LayerSection({required this.layer, required this.items, required this.totalInDomain, required this.open, required this.adding, required this.searching});
  final LayerDef layer;

  /// Items after the domain filter and search.
  final List<MemoryItem> items;

  /// Items after the domain filter only (to tell "no matches" from "empty").
  final int totalInDomain;
  final bool open, adding, searching;

  String get emptyLabel => searching && totalInDomain > 0 ? 'No matches' : 'Add the first one';

  String get addNote => switch (layer.id) {
        'identity' => 'Stable fact. Future edits need confirmation.',
        'preference' => 'I’ll check in after $staleDays days.',
        'pattern' => 'Saved as something you told me, not an inference.',
        _ => 'Auto-deletes in $expiryDays days.',
      };
}

class MemoryState {
  const MemoryState({
    this.searchOpen = false,
    this.overviewOpen = false,
    this.addingFor,
    this.query = '',
    this.domF = 'all',
    this.filter = 'all',
    this.total = 0,
    this.counts = const {},
    this.sections = const [],
  });
  final String? addingFor;
  final bool searchOpen, overviewOpen;
  final String query, domF, filter;
  final int total;

  /// Memories per layer (unfiltered), for the overview card.
  final Map<String, int> counts;
  final List<LayerSection> sections;

  bool dimmed(String layerId) => filter != 'all' && filter != layerId;

  MemoryState copyWith({bool? searchOpen, bool? overviewOpen, String? Function()? addingFor, String? query, String? domF, String? filter}) => MemoryState(
        searchOpen: searchOpen ?? this.searchOpen,
        overviewOpen: overviewOpen ?? this.overviewOpen,
        addingFor: addingFor != null ? addingFor() : this.addingFor,
        query: query ?? this.query,
        domF: domF ?? this.domF,
        filter: filter ?? this.filter,
        total: total,
        counts: counts,
        sections: sections,
      );
}

/// Filters and disclosure (the UI-only fields of [MemoryState]); reset per account.
class _MemoryUiController extends Notifier<MemoryState> {
  @override
  MemoryState build() {
    ref.watch(sessionProvider.select((s) => s.user));
    return const MemoryState();
  }

  void set(MemoryState ui) => state = ui;
}

final _memoryUiProvider = NotifierProvider<_MemoryUiController, MemoryState>(_MemoryUiController.new);

/// Memory tab. Filters live on their own provider so they survive tab switches
/// (and You → "view memories").
class MemoryViewModel extends Notifier<MemoryState> {
  @override
  MemoryState build() => _derive(ref.watch(_memoryUiProvider), ref.watch(accountProvider), ref.watch(clockProvider)());

  static MemoryState _derive(MemoryState ui, AccountData a, DateTime now) {
    final q = ui.query.trim().toLowerCase();
    MemoryItem item(Memory m) {
      final c = m.conn == null ? null : connById[m.conn];
      return MemoryItem(
        m: m,
        meta: switch (m.layer) {
          'preference' => 'Confirmed ${fmtDate(m.confirmed ?? m.created)}',
          'pattern' => m.basis ?? 'You told me',
          _ => '${c?.name ?? src[m.source]!.name} · ${fmtDate(m.created)}',
        },
        stale: isStale(m, now),
        daysLeft: daysLeft(m, now),
      );
    }

    final sections = [
      for (final L in layers.where((L) => ui.filter == 'all' || ui.filter == L.id))
        () {
          final inDomain = a.mem.where((m) => m.layer == L.id && (ui.domF == 'all' || m.dom == ui.domF)).toList();
          final matches = q.isEmpty ? inDomain : inDomain.where((m) => '${m.text} ${src[m.source]!.name} ${m.conn ?? ''} ${m.detail}'.toLowerCase().contains(q));
          return LayerSection(
            layer: L,
            items: [for (final m in matches) item(m)],
            totalInDomain: inDomain.length,
            open: (a.openL[L.id] ?? false) || q.isNotEmpty,
            adding: ui.addingFor == L.id,
            searching: q.isNotEmpty,
          );
        }(),
    ];
    return MemoryState(
      searchOpen: ui.searchOpen,
      overviewOpen: ui.overviewOpen,
      addingFor: ui.addingFor,
      query: ui.query,
      domF: ui.domF,
      filter: ui.filter,
      total: a.mem.length,
      counts: {for (final L in layers) L.id: a.count((m) => m.layer == L.id)},
      sections: sections,
    );
  }

  AccountController get _account => ref.read(accountProvider.notifier);
  void _set(MemoryState ui) => ref.read(_memoryUiProvider.notifier).set(ui);

  void toggleSearch() {
    final open = !state.searchOpen;
    _set(state.copyWith(searchOpen: open, query: open ? state.query : ''));
  }

  void setQuery(String q) => _set(state.copyWith(query: q));
  void setDomain(String id) => _set(state.copyWith(domF: id));
  void toggleOverview() => _set(state.copyWith(overviewOpen: !state.overviewOpen));

  /// Filters to one layer (and opens it); tapping the same layer clears the filter.
  void setFilter(String id) {
    if (state.filter == id) {
      _set(state.copyWith(filter: 'all'));
    } else {
      _set(state.copyWith(filter: id));
      _account.setLayerOpen(id, true);
    }
  }

  void toggleLayer(String id) {
    if (state.addingFor == id) _set(state.copyWith(addingFor: () => null));
    _account.setLayerOpen(id, !(ref.read(accountProvider).openL[id] ?? false));
  }

  void startAdd(String id) => _set(state.copyWith(addingFor: () => id));
  void cancelAdd() => _set(state.copyWith(addingFor: () => null));

  void add(String layer, String text) {
    _account.add(layer, text, domain: state.domF == 'all' ? null : state.domF);
    _account.setLayerOpen(layer, true);
    cancelAdd();
  }

  /// Jump here from You: one domain, every layer open.
  void showDomain(String id) {
    _set(state.copyWith(domF: id, filter: 'all'));
    _account.openAllLayers();
  }

  void forget(String id) => _account.forget(id);
  void reconfirm(String id) => _account.reconfirm(id);
}

final memoryViewModelProvider = NotifierProvider<MemoryViewModel, MemoryState>(MemoryViewModel.new);
