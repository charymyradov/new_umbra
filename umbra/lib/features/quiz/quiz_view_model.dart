import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../state/account_controller.dart';
import '../shell/shell_view_model.dart';

enum QuizStage { intro, question, done }

class QuizState {
  const QuizState({
    required this.dom,
    required this.xpBefore,
    this.stage = QuizStage.intro,
    this.index = 0,
    this.swipe = 0,
    this.xp = 0,
    this.picked = const [],
    this.saved = const [],
    this.text = '',
  });
  final String dom;

  /// Account XP when the quiz opened, to detect a level-up.
  final int xpBefore;
  final QuizStage stage;

  /// Current question, and current statement within a swipe question.
  final int index, swipe;

  /// XP earned so far in this run.
  final int xp;
  final List<String> picked;
  final List<QuizItem> saved;
  final String text;

  Quest get quest => quests[dom]!;
  Domain get domain => domainById[dom]!;
  Question get question => quest.qs[index];
  int get total => quest.qs.length;
  (String, String) get statement => question.items[swipe];

  bool get canContinue => switch (question.type) {
        QType.multi => picked.isNotEmpty,
        QType.text => text.trim().isNotEmpty,
        _ => false,
      };

  String get continueLabel => question.type == QType.multi ? (picked.isEmpty ? 'Pick at least one' : 'Continue · ${picked.length}') : 'Continue';

  LevelInfo get levelAfter => levelFor(xpBefore + xp);
  bool get leveledUp => levelAfter.index > levelFor(xpBefore).index;
  String get commitLabel => saved.isEmpty ? 'Done' : 'Save ${saved.length} to memory';

  QuizState copyWith({QuizStage? stage, int? index, int? swipe, int? xp, List<String>? picked, List<QuizItem>? saved, String? text}) => QuizState(
        dom: dom,
        xpBefore: xpBefore,
        stage: stage ?? this.stage,
        index: index ?? this.index,
        swipe: swipe ?? this.swipe,
        xp: xp ?? this.xp,
        picked: picked ?? this.picked,
        saved: saved ?? this.saved,
        text: text ?? this.text,
      );
}

/// One run through a domain quiz. Answers are collected here and only written
/// to memory on [commit].
class QuizViewModel extends Notifier<QuizState> {
  QuizViewModel(this.dom);
  final String dom;

  @override
  QuizState build() => QuizState(dom: dom, xpBefore: ref.read(accountProvider).xp);

  QuizItem? _item(String? text, String answer, {int? suffix, String? prompt}) {
    if (text == null) return null;
    final q = state.question;
    return QuizItem(
      id: 'q_${dom}_${q.id}${suffix != null ? '_$suffix' : ''}',
      layer: q.layer ?? 'preference',
      text: text,
      domain: dom,
      sensitive: state.quest.sensitive,
      q: prompt ?? q.q,
      a: answer,
    );
  }

  void _advance(List<QuizItem?> items, {required bool answered}) {
    final next = state.index + 1;
    state = state.copyWith(
      saved: [...state.saved, ...items.whereType<QuizItem>()],
      xp: state.xp + (answered ? xpPerAnswer : 0),
      index: next < state.total ? next : state.index,
      swipe: 0,
      picked: const [],
      text: '',
      stage: next >= state.total ? QuizStage.done : QuizStage.question,
    );
  }

  void start() => state = state.copyWith(stage: QuizStage.question);

  void skip() => _advance(const [], answered: false);

  /// Duo and scale questions answer on tap.
  void answer(String a) => _advance([_item(state.question.save?.call(a, const []), a)], answered: true);

  void togglePick(String o) {
    final p = state.picked;
    if (p.contains(o)) {
      state = state.copyWith(picked: p.where((x) => x != o).toList());
    } else if (p.length < state.question.max) {
      state = state.copyWith(picked: [...p, o]);
    }
  }

  void setText(String v) => state = state.copyWith(text: v);

  /// Multi-select and free-text questions need an explicit Continue.
  void submit() {
    if (!state.canContinue) return;
    final q = state.question;
    if (q.type == QType.multi) {
      final a = state.picked.join(', ');
      _advance([_item(q.save?.call(a, state.picked), a)], answered: true);
    } else {
      final v = state.text.trim();
      _advance([_item(q.save?.call(v, const []), v)], answered: true);
    }
  }

  /// "That's me" / "Not me" on the current statement.
  void swipe(bool yes) {
    final (prompt, saves) = state.statement;
    final it = yes ? _item(saves, 'That’s me', suffix: state.swipe, prompt: prompt) : null;
    if (state.swipe + 1 >= state.question.items.length) {
      _advance([it], answered: true);
    } else {
      state = state.copyWith(swipe: state.swipe + 1, saved: it == null ? null : [...state.saved, it]);
    }
  }

  void drop(int i) => state = state.copyWith(saved: [...state.saved]..removeAt(i));

  void commit() {
    ref.read(accountProvider.notifier).commitQuest(dom, state.saved, state.xp);
    ref.read(shellViewModelProvider.notifier).goTab('you');
  }
}

final quizViewModelProvider = NotifierProvider.autoDispose.family<QuizViewModel, QuizState, String>(QuizViewModel.new);
