import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import 'quiz_view_model.dart';

Future<void> openQuiz(BuildContext context, String dom) => Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => QuizView(dom: dom),
      transitionsBuilder: (_, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: easeOutSoft);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(c), child: child),
        );
      },
    ));

class QuizView extends ConsumerStatefulWidget {
  const QuizView({super.key, required this.dom});
  final String dom;

  @override
  ConsumerState<QuizView> createState() => _QuizViewState();
}

/// Flow, answers and XP live in [QuizViewModel]; this state only holds the text
/// controller and the swipe card's drag offset (pure gesture feedback).
class _QuizViewState extends ConsumerState<QuizView> {
  late QuizState st;
  final _text = TextEditingController();
  Offset _drag = Offset.zero;
  bool _dragging = false;

  QuizViewModel get vm => ref.read(quizViewModelProvider(widget.dom).notifier);
  Quest get quest => st.quest;
  Domain get d => st.domain;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _commit() {
    vm.commit();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    st = ref.watch(quizViewModelProvider(widget.dom));
    ref.listen(quizViewModelProvider(widget.dom).select((s) => (s.index, s.swipe)), (_, _) {
      _text.clear();
      _drag = Offset.zero;
    });
    final n = quest.qs.length;
    return Scaffold(
      backgroundColor: d.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 44,
              child: Row(children: [
                RoundIconButton(icon: UI.close, label: 'Close quiz', size: 36, onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(children: [
                    for (var j = 0; j < n; j++) ...[
                      if (j > 0) const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(color: st.stage == QuizStage.done || j < st.index ? d.color : const Color(0x1F2B2620), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: d.color, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text('${st.xp} XP', style: sans(13, color: C.card, weight: FontWeight.w600)),
                ),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: easeOutSoft,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a), child: c),
                ),
                child: KeyedSubtree(
                  key: ValueKey('${st.stage}-${st.index}'),
                  child: switch (st.stage) {
                    QuizStage.intro => _intro(),
                    QuizStage.question => _question(),
                    QuizStage.done => _done(),
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _intro() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 36),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: d.color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(offset: Offset(0, 18), blurRadius: 30, spreadRadius: -16, color: Color(0x8C2B2620))],
                ),
                alignment: Alignment.center,
                child: UIcon(UI.forDomain(d.id), size: 38, color: C.card, stroke: 1.6),
              ),
              const SizedBox(height: 24),
              Text('${d.name} quiz'.toUpperCase(), style: caps(12, color: d.color)),
              const SizedBox(height: 10),
              Text(quest.title, style: serif(40, height: 1.05)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _introStat('${quest.qs.length}', 'questions')),
                const SizedBox(width: 8),
                Expanded(child: _introStat('1', 'minute')),
                const SizedBox(width: 8),
                Expanded(child: _introStat('${quest.maxXp}', 'XP to earn', color: d.color)),
              ]),
              if (quest.sensitive) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    UIcon(UI.lock, size: 18, color: d.color, stroke: 1.8),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Answers are marked private and left out of exports unless you choose otherwise.', style: sans(13, height: 1.4))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              Text('Answers save as things you told me. Skip anything.', style: sans(13, color: C.body, height: 1.45)),
            ]),
          ),
        ),
        PillButton(label: 'Start', height: 58, fontSize: 16, onTap: vm.start),
      ]);

  Widget _introStat(String v, String k, {Color? color}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: serif(26, color: color, height: 1)),
          const SizedBox(height: 4),
          Text(k, style: sans(12, color: C.muted)),
        ]),
      );

  Widget _question() {
    final q = st.question;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 28),
      Row(children: [
        Text('${st.index + 1} of ${quest.qs.length}'.toUpperCase(), style: caps(12, color: d.color, spacing: .06)),
        if (quest.sensitive) ...[
          const SizedBox(width: 8),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(11)),
            child: Row(children: [
              UIcon(UI.lock, size: 11, color: d.color),
              const SizedBox(width: 4),
              Text('Private', style: sans(12, color: d.color)),
            ]),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Text(q.q, style: serif(32, height: 1.1)),
      if (q.sub != null) ...[const SizedBox(height: 8), Text(q.sub!, style: sans(14, color: C.body))],
      const SizedBox(height: 22),
      Expanded(
        child: switch (q.type) {
          QType.duo => _duo(q),
          QType.multi => _multi(q),
          QType.scale => _scale(q),
          QType.swipe => _swipeView(q),
          QType.text => Align(
              alignment: Alignment.topCenter,
              child: UField(
                controller: _text,
                hint: q.ph,
                serifFont: true,
                fontSize: 19,
                height: 62,
                radius: 20,
                autofocus: true,
                action: TextInputAction.done,
                capitalization: TextCapitalization.words,
                onChanged: vm.setText,
                onSubmitted: (_) => vm.submit(),
              ),
            ),
        },
      ),
      Row(children: [
        TextLink('Skip', size: 15, height: 54, onTap: vm.skip),
        const SizedBox(width: 20),
        if (q.type == QType.multi || q.type == QType.text)
          Expanded(
            child: PillButton(
              label: st.continueLabel,
              height: 54,
              enabled: st.canContinue,
              onTap: vm.submit,
            ),
          ),
      ]),
    ]);
  }

  Widget _duo(Question q) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 300,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (i, o) in q.duo.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Pressable(
                  onTap: () => vm.answer(o.label),
                  label: o.label,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: o.bg,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [BoxShadow(offset: Offset(0, 16), blurRadius: 30, spreadRadius: -20, color: Color(0xB32B2620))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(o.label, style: serif(27, color: o.fg, height: 1.05)),
                      const SizedBox(height: 8),
                      Opacity(opacity: .8, child: Text(o.sub, style: sans(12, color: o.fg, height: 1.35))),
                    ]),
                  ),
                ),
              ),
            ],
          ]),
        ),
      );

  Widget _multi(Question q) => SingleChildScrollView(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in q.opts)
            Builder(builder: (_) {
              final on = st.picked.contains(o);
              return Pressable(
                onTap: () => vm.togglePick(o),
                label: o,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: on ? d.color : C.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: on ? d.color : Colors.transparent, width: 1.5),
                  ),
                  child: Text(o, style: sans(15, color: on ? C.card : C.ink)),
                ),
              );
            }),
        ]),
      );

  Widget _scale(Question q) => SingleChildScrollView(
        child: Column(children: [
          for (final (j, o) in q.opts.indexed) ...[
            if (j > 0) const SizedBox(height: 8),
            Pressable(
              onTap: () => vm.answer(o),
              label: o,
              child: Container(
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
                child: Stack(children: [
                  FractionallySizedBox(widthFactor: (j + 1) / q.opts.length, child: Container(color: d.color.withValues(alpha: .17))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Align(alignment: Alignment.centerLeft, child: Text(o, style: sans(15)))),
                ]),
              ),
            ),
          ],
        ]),
      );

  Widget _swipeView(Question q) {
    final item = st.statement;
    final w = MediaQuery.of(context).size.width;
    final tilt = (_drag.dx / w).clamp(-1.0, 1.0);
    return Column(children: [
      SizedBox(
        height: 264,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 20, right: 20, top: 18, bottom: 0, child: _deck(.5)),
          Positioned(left: 10, right: 10, top: 9, bottom: 7, child: _deck(.85)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 250,
            child: GestureDetector(
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (e) => setState(() => _drag += e.delta),
              onPanEnd: (e) {
                final dx = _drag.dx + e.velocity.pixelsPerSecond.dx * .15;
                setState(() => _dragging = false);
                if (dx.abs() > w * .28) {
                  vm.swipe(dx > 0);
                } else {
                  setState(() => _drag = Offset.zero);
                }
              },
              child: AnimatedContainer(
                key: ValueKey(st.swipe),
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 260),
                curve: easeOutSoft,
                transform: Matrix4.translationValues(_drag.dx, _drag.dy * .3, 0)..rotateZ(tilt * 12 * math.pi / 180),
                transformAlignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: d.color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(offset: Offset(0, 18), blurRadius: 30, spreadRadius: -18, color: Color(0xB32B2620))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Opacity(opacity: .75, child: Text('${st.swipe + 1} / ${q.items.length}', style: sans(12, color: C.card))),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: tilt.abs() > .08 ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
                        child: Text(tilt > 0 ? 'That’s me' : 'Not me', style: sans(12, color: d.color, weight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                  Text(item.$1, style: serif(28, color: C.card, height: 1.15)),
                ]),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: PillButton(label: 'Not me', height: 56, bg: C.card, fg: C.ink, weight: FontWeight.w400, onTap: () => vm.swipe(false))),
        const SizedBox(width: 10),
        Expanded(child: PillButton(label: 'That’s me', height: 56, onTap: () => vm.swipe(true))),
      ]),
    ]);
  }

  Widget _deck(double opacity) => Container(decoration: BoxDecoration(color: C.card.withValues(alpha: opacity), borderRadius: BorderRadius.circular(28)));

  Widget _done() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 24),
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: st.xp.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Text('+${v.round()}', style: serif(60, color: d.color, height: 1)),
        ),
      ),
      const SizedBox(height: 6),
      Center(child: Text('XP EARNED', style: caps(12, color: C.body))),
      if (st.leveledUp) ...[
        const SizedBox(height: 14),
        Center(
          child: PopIn(
            delay: const Duration(milliseconds: 300),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text('Level up · ${st.levelAfter.name}', style: sans(13, color: C.gold)),
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      Text('What I’ll remember', style: serif(21)),
      const SizedBox(height: 18),
      Expanded(
        child: st.saved.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Nothing to save. That’s fine.', textAlign: TextAlign.center, style: sans(14, color: C.body)),
              )
            : ListView.separated(
                itemCount: st.saved.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, j) {
                  final it = st.saved[j];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      LayerShape(it.layer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.text, style: serif(16, height: 1.3)),
                          const SizedBox(height: 2),
                          Text(layerById[it.layer]!.name, style: sans(11, color: C.muted)),
                        ]),
                      ),
                      RoundIconButton(icon: UI.close, label: 'Don’t save', iconSize: 10, bg: C.paper, fg: C.muted, onTap: () => vm.drop(j)),
                    ]),
                  );
                },
              ),
      ),
      const SizedBox(height: 18),
      PillButton(label: st.commitLabel, height: 58, fontSize: 16, onTap: _commit),
    ]);
  }
}
