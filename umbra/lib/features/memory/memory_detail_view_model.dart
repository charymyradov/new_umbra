import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';

enum EditStage { none, edit, review }

class MemoryDetailState {
  const MemoryDetailState({required this.memory, required this.now, required this.uses, this.stage = EditStage.none, this.draft = ''});

  /// Null once the memory is forgotten — the sheet closes itself.
  final Memory? memory;
  final DateTime now;

  /// Titles of today's suggestions this memory shapes.
  final List<String> uses;
  final EditStage stage;

  /// Proposed text while an identity change is being reviewed.
  final String draft;

  Memory get m => memory!;
  LayerDef get layer => layerById[m.layer]!;
  Src get source => src[m.source]!;
  Conn? get conn => m.conn == null ? null : connById[m.conn];
  String get sourceLine => '${source.name}${conn != null ? ' · ${conn!.name}' : ''}';
  String get certainty => m.source == 'explicit' ? 'You said it' : (m.layer == 'pattern' ? 'Inferred · you confirmed' : 'Observed · you confirmed');
  bool get isIdentity => m.layer == 'identity';
  int get daysLeftCount => daysLeft(m, now);
  DateTime get expires => expiresAt(m);

  List<(String, String)> get facts => [
        ('Recorded', fmtDate(m.created)),
        ('Source', '${source.code} · ${source.name}'),
        if (m.layer == 'pattern' && m.confidence != null) ('Confidence', '${confWord(m.confidence!)} · ${(m.confidence! * 100).round()}%'),
        if (m.layer == 'live') ('Auto-deletes', fmtDate(expires)),
      ];

  MemoryDetailState copyWith({EditStage? stage, String? draft}) =>
      MemoryDetailState(memory: memory, now: now, uses: uses, stage: stage ?? this.stage, draft: draft ?? this.draft);
}

class MemoryDetailViewModel extends Notifier<MemoryDetailState> {
  MemoryDetailViewModel(this.id);
  final String id;

  @override
  MemoryDetailState build() {
    final m = ref.watch(accountProvider.select((a) => a.memById(id)));
    final uses = ref.watch(planProvider).where((p) => p.s.uses.contains(id)).map((p) => p.s.title).toList();
    final prev = stateOrNull;
    return MemoryDetailState(memory: m, now: ref.watch(clockProvider)(), uses: uses, stage: prev?.stage ?? EditStage.none, draft: prev?.draft ?? '');
  }

  AccountController get _account => ref.read(accountProvider.notifier);

  void startEdit() => state = state.copyWith(stage: EditStage.edit);
  void cancel() => state = state.copyWith(stage: EditStage.none);

  /// Identity changes go through a before/after review; everything else saves straight away.
  void submit(String text) {
    if (text.trim().isEmpty) return;
    if (state.isIdentity) {
      state = state.copyWith(stage: EditStage.review, draft: text.trim());
    } else {
      _account.edit(id, text);
      cancel();
    }
  }

  void confirmReview() {
    _account.edit(id, state.draft);
    cancel();
  }

  void forget() => _account.forget(id);
  void reconfirm() => _account.reconfirm(id);
}

final memoryDetailViewModelProvider =
    NotifierProvider.autoDispose.family<MemoryDetailViewModel, MemoryDetailState, String>(MemoryDetailViewModel.new);
