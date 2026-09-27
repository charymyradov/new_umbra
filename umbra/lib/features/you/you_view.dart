import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../quiz/quiz_view.dart';
import '../shell/shell_view.dart';
import 'you_view_model.dart';

class YouView extends ConsumerWidget {
  const YouView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(youViewModelProvider);
    final vm = ref.read(youViewModelProvider.notifier);
    final overall = s.overall;
    final lv = s.level;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, tabBottomPad(context)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'You, '),
            TextSpan(text: 'so far', style: serif(38, italic: true, color: C.amber, height: 1, spacing: -.015)),
          ]), style: serif(38, height: 1, spacing: -.015)),
        ),
        const SizedBox(height: 22),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: C.ink,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(offset: Offset(0, 24), blurRadius: 44, spreadRadius: -26, color: Color(0xCC2B2620))],
          ),
          child: Stack(children: [
            Positioned(
              right: -60,
              top: -60,
              width: 200,
              height: 200,
              child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x24E9C98A)))),
            ),
            Positioned(
              right: -20,
              top: -20,
              width: 120,
              height: 120,
              child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x1AE9C98A)))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(children: [
                Row(children: [
                  Ring(
                    pct: overall / 100,
                    color: C.gold,
                    track: C.inkLine,
                    size: 112,
                    thickness: 8,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$overall%', style: serif(34, color: C.paper, height: 1)),
                      const SizedBox(height: 2),
                      Text('KNOWN', style: caps(10, color: C.onDarkMuted, spacing: .1)),
                    ]),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('LEVEL ${lv.index + 1}', style: caps(11, color: C.gold, spacing: .1)),
                      const SizedBox(height: 10),
                      Text(lv.name, style: serif(28, italic: true, color: C.paper, height: 1)),
                      const SizedBox(height: 10),
                      Row(children: [
                        for (var j = 0; j < levels.length; j++) ...[
                          if (j > 0) const SizedBox(width: 4),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 6,
                              decoration: BoxDecoration(color: j <= lv.index ? C.gold : const Color(0xFF4A453E), borderRadius: BorderRadius.circular(3)),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 10),
                      Text(s.nextLevelLine, style: sans(11, color: C.onDarkMuted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: _Stat(icon: UI.bolt, iconColor: C.gold, value: '${s.xp}', label: 'XP')),
                  const SizedBox(width: 8),
                  Expanded(child: _Stat(icon: UI.flame, iconColor: C.sun, value: '${s.streak}', label: 'Day streak')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                        icon: UI.checkCircle,
                        iconColor: C.tealLight,
                        stroke: 2.2,
                        value: '${s.quizzes}',
                        label: 'Quizzes'),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        for (final card in s.cards) ...[
          _DomainCard(card: card, vm: vm),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: SectionLabel('Coming soon')),
        const SizedBox(height: 12),
        Row(children: [
          for (final (i, (label, icon)) in const [('Food', UI.food), ('Film & TV', UI.film), ('Travel', UI.travel), ('Style', UI.style)].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DashedBox(radius: 22, child: Center(child: UIcon(icon, size: 20, color: const Color(0xFFA89D8C)))),
                ),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: sans(11, color: C.muted, height: 1.2)),
              ]),
            ),
          ],
        ]),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.iconColor, required this.value, required this.label, this.stroke});
  final UI icon;
  final Color iconColor;
  final String value, label;
  final double? stroke;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.inkSoft, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UIcon(icon, size: 18, color: iconColor, stroke: stroke),
          const SizedBox(height: 8),
          Text(value, style: serif(24, color: C.paper, height: 1)),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: caps(10, color: C.onDarkMuted)),
        ]),
      );
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({required this.card, required this.vm});
  final DomainCardState card;
  final YouViewModel vm;

  @override
  Widget build(BuildContext context) {
    final d = card.domain;
    final open = card.open;
    final pct = card.depth;
    final done = card.quizDone;
    final chips = card.chips;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: open ? d.bg : C.card, borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => vm.toggle(d.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(children: [
              Ring(
                pct: pct / 100,
                color: d.color,
                track: d.bg,
                size: 56,
                thickness: 5,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: UIcon(UI.forDomain(d.id), size: 22, color: C.card),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: serif(22, height: 1.05)),
                  const SizedBox(height: 5),
                  if (done)
                    Row(children: [
                      UIcon(UI.check, size: 11, color: d.color),
                      const SizedBox(width: 4),
                      Text('Quiz done', style: sans(11, color: d.color)),
                    ])
                  else
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const UIcon(UI.bolt, size: 9, color: C.gold),
                        const SizedBox(width: 4),
                        Text('+${card.quizXp}', style: sans(10, color: C.gold)),
                      ]),
                    ),
                ]),
              ),
              Text('$pct%', style: serif(24, color: d.color)),
              const SizedBox(width: 12),
              Chevron(open: open),
            ]),
          ),
        ),
        Reveal(
          open: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (chips.isNotEmpty) ...[
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final chip in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(13)),
                      child: Text(chip, style: serif(14, height: 1.25)),
                    ),
                ]),
                const SizedBox(height: 14),
              ],
              Row(children: [
                Expanded(
                  child: PillButton(
                    label: done ? 'Replay quiz' : 'Play quiz',
                    height: 48,
                    fontSize: 14,
                    bg: d.color,
                    fg: C.card,
                    icon: const UIcon(UI.play, size: 14, color: C.card),
                    onTap: () => openQuiz(context, d.id),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  label: 'View ${d.name} memories',
                  onTap: () => vm.viewMemories(d.id),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24)),
                    child: Row(children: [
                      Text('${card.memories}', style: sans(14, color: d.color)),
                      const SizedBox(width: 8),
                      UIcon(UI.chevRight, size: 12, color: d.color),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
