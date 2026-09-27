import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/catalog.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../memory/memory_view_model.dart';
import '../shell/shell_view_model.dart';

class DomainCardState {
  const DomainCardState({required this.domain, required this.memories, required this.chips, required this.depth, required this.quizDone, required this.open});
  final Domain domain;
  final int memories;

  /// The latest few things known in this domain, clipped for chips.
  final List<String> chips;

  /// 0–100: how well Umbra knows this part of you.
  final int depth;
  final bool quizDone, open;

  int get quizXp => quests[domain.id]!.maxXp;
}

class YouState {
  const YouState({required this.open, required this.overall, required this.level, required this.xp, required this.streak, required this.quizzes, required this.cards});
  final Set<String> open;
  final int overall, xp, streak, quizzes;
  final LevelInfo level;
  final List<DomainCardState> cards;

  String get nextLevelLine => level.next != null ? '${level.next! - xp} XP to ${levels[level.index + 1].$2}' : 'Top level';
}

class YouViewModel extends Notifier<YouState> {
  @override
  YouState build() {
    final a = ref.watch(accountProvider);
    final open = stateOrNull?.open ?? const <String>{};
    // Domains picked during onboarding come first.
    final ordered = [...domains.where((d) => a.chosenDomains.contains(d.id)), ...domains.where((d) => !a.chosenDomains.contains(d.id))];
    return YouState(
      open: open,
      overall: (domains.fold<int>(0, (s, d) => s + a.domainDepth(d.id)) / domains.length).round(),
      level: levelFor(a.xp),
      xp: a.xp,
      streak: a.streak,
      quizzes: domains.where((d) => a.questsDone.contains(d.id)).length,
      cards: [
        for (final d in ordered)
          () {
            final items = a.mem.where((m) => m.dom == d.id).toList();
            return DomainCardState(
              domain: d,
              memories: items.length,
              chips: [for (final m in items.skip(items.length > 3 ? items.length - 3 : 0)) clip(m.text, 30)],
              depth: a.domainDepth(d.id),
              quizDone: a.questsDone.contains(d.id),
              open: open.contains(d.id),
            );
          }(),
      ],
    );
  }

  void toggle(String id) {
    final open = {...state.open};
    open.contains(id) ? open.remove(id) : open.add(id);
    state = YouState(
      open: open,
      overall: state.overall,
      level: state.level,
      xp: state.xp,
      streak: state.streak,
      quizzes: state.quizzes,
      cards: [
        for (final c in state.cards)
          DomainCardState(domain: c.domain, memories: c.memories, chips: c.chips, depth: c.depth, quizDone: c.quizDone, open: open.contains(c.domain.id)),
      ],
    );
  }

  /// Opens Memory filtered to this domain.
  void viewMemories(String id) {
    ref.read(memoryViewModelProvider.notifier).showDomain(id);
    ref.read(shellViewModelProvider.notifier).goTab('memory');
  }
}

final youViewModelProvider = NotifierProvider.autoDispose<YouViewModel, YouState>(YouViewModel.new);
