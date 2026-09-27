import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../shell/shell_view.dart';
import 'games_view_model.dart';

class GamesView extends ConsumerWidget {
  const GamesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(gamesViewModelProvider);
    final vm = ref.read(gamesViewModelProvider.notifier);
    const rots = [-5.0, 4.0, -3.0, 5.0, -4.0, 3.0];
    // Lay out like CSS grid auto-flow: an open card spans both columns.
    final rows = <Widget>[];
    final buf = <Widget>[];
    void flush() {
      if (buf.isEmpty) return;
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: buf[0]),
        const SizedBox(width: 12),
        Expanded(child: buf.length > 1 ? buf[1] : const SizedBox.shrink()),
      ]));
      buf.clear();
    }

    for (final (i, g) in games.indexed) {
      final open = st.open == g.id;
      final card = _GameCard(
        g: g,
        open: open,
        rot: rots[i % rots.length],
        onToggle: () => vm.toggle(g.id),
        onPlay: () => vm.play(g),
      );
      if (open) {
        flush();
        rows.add(card);
      } else {
        buf.add(card);
        if (buf.length == 2) flush();
      }
    }
    flush();

    return DefaultTextStyle.merge(
      style: fredoka(14),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, tabBottomPad(context)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              const SizedBox.square(dimension: 52, child: CustomPaint(painter: _LogoPainter())),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('setir', style: fredoka(36, weight: FontWeight.w600, height: 1)),
                Text('games we make', style: fredoka(14, color: C.muted)),
              ]),
            ]),
          ),
          const SizedBox(height: 22),
          _Featured(
            index: st.featured,
            onIndex: vm.feature,
            onPlay: () => vm.play(st.featuredGame),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Expanded(child: Text('All games', style: fredoka(22, weight: FontWeight.w600))),
              Text('${games.length} games', style: fredoka(13, color: C.muted)),
            ]),
          ),
          const SizedBox(height: 22),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: easeOutSoft,
            alignment: Alignment.topCenter,
            child: Column(children: [
              for (final (i, r) in rows.indexed) ...[if (i > 0) const SizedBox(height: 12), r],
            ]),
          ),
          const SizedBox(height: 12),
          DashedBox(
            radius: 26,
            width: 2,
            height: 76,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: C.sand, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const UIcon(UI.plus, size: 14, color: C.muted, stroke: 2.4),
              ),
              const SizedBox(width: 10),
              Text('More on the way', style: fredoka(15, color: C.muted)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(const Offset(15, 23), 15, Paint()..color = const Color(0xFFF2A93B));
    final m = Paint()..blendMode = BlendMode.multiply;
    canvas.drawCircle(const Offset(33, 15), 15, m..color = const Color(0xFFE5476A));
    canvas.drawCircle(const Offset(29, 35), 15, m..color = const Color(0xFF2F72C9));
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

class _Featured extends StatelessWidget {
  const _Featured({required this.index, required this.onIndex, required this.onPlay});
  final int index;
  final ValueChanged<int> onIndex;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final g = games[index % games.length];
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 200) return;
        onIndex((index + (v < 0 ? 1 : -1)) % games.length);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        constraints: const BoxConstraints(minHeight: 236),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: g.color,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [BoxShadow(offset: const Offset(0, 24), blurRadius: 40, spreadRadius: -24, color: g.color)],
        ),
        child: Stack(children: [
          Positioned(right: -30, top: -30, width: 170, height: 170, child: Container(decoration: const BoxDecoration(color: Color(0x24FFFDF8), shape: BoxShape.circle))),
          Positioned(right: 120, top: 22, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFFFE08A), shape: BoxShape.circle))),
          Positioned(
            right: 30,
            top: 170,
            child: Transform.rotate(
              angle: 20 * math.pi / 180,
              child: Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0x99FFFDF8), borderRadius: BorderRadius.circular(3))),
            ),
          ),
          Positioned(right: 150, top: 70, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0x80FFFDF8), shape: BoxShape.circle))),
          Positioned(
            left: 24,
            top: 24,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(color: const Color(0x38FFFDF8), borderRadius: BorderRadius.circular(13)),
              child: Row(children: [
                const UIcon(UI.star, size: 11, color: C.card),
                const SizedBox(width: 5),
                Text('Featured', style: fredoka(12, color: C.card, weight: FontWeight.w500)),
              ]),
            ),
          ),
          Positioned(
            right: 26,
            top: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: easeSpring,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
              child: Transform.rotate(
                key: ValueKey(g.id),
                angle: -9 * math.pi / 180,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [BoxShadow(offset: Offset(0, 18), blurRadius: 30, spreadRadius: -14, color: Color(0x66000000))],
                  ),
                  alignment: Alignment.center,
                  child: UIcon(UI.forGame(g.icon), size: 52, color: g.color),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 150, 22, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(g.name, style: fredoka(32, color: C.card, weight: FontWeight.w600, height: 1.05)),
              const SizedBox(height: 2),
              Opacity(opacity: .9, child: Text(g.genre, style: fredoka(14, color: C.card))),
              const SizedBox(height: 14),
              Row(children: [
                Pressable(
                  onTap: onPlay,
                  scale: .94,
                  label: 'Play ${g.name}',
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
                    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(23)),
                    child: Row(children: [
                      UIcon(UI.play, size: 14, color: g.color),
                      const SizedBox(width: 8),
                      Text('Play', style: fredoka(16, color: g.color, weight: FontWeight.w600)),
                    ]),
                  ),
                ),
                const Spacer(),
                for (var i = 0; i < games.length; i++)
                  GestureDetector(
                    onTap: () => onIndex(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(color: i == index ? C.card : const Color(0x73FFFDF8), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.g, required this.open, required this.rot, required this.onToggle, required this.onPlay});
  final Game g;
  final bool open;
  final double rot;
  final VoidCallback onToggle, onPlay;

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedRotation(
      turns: open ? 0 : rot / 360,
      duration: const Duration(milliseconds: 400),
      curve: easeSpring,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: g.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(offset: const Offset(0, 10), blurRadius: 18, spreadRadius: -10, color: g.color)],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: const Border(bottom: BorderSide(color: Color(0x1F000000), width: 3)),
        ),
        alignment: Alignment.center,
        child: UIcon(UI.forGame(g.icon), size: 30, color: C.card),
      ),
    );
    return Pressable(
      onTap: onToggle,
      label: g.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: open ? g.tint : C.card, borderRadius: BorderRadius.circular(28)),
        child: open
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.name, style: fredoka(22, weight: FontWeight.w600, height: 1.05)),
                      const SizedBox(height: 4),
                      _Genre(g: g, bg: C.card),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text(g.blurb, style: fredoka(14, color: C.body, height: 1.4))),
                  const SizedBox(width: 12),
                  Pressable(
                    onTap: onPlay,
                    scale: .94,
                    label: 'Play ${g.name}',
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: g.color, borderRadius: BorderRadius.circular(22)),
                      child: Row(children: [
                        const UIcon(UI.play, size: 12, color: C.card),
                        const SizedBox(width: 6),
                        Text('Play', style: fredoka(15, color: C.card, weight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                icon,
                const SizedBox(height: 12),
                Text(g.name, style: fredoka(17, weight: FontWeight.w600, height: 1.1)),
                const SizedBox(height: 6),
                _Genre(g: g, bg: g.tint),
              ]),
      ),
    );
  }
}

class _Genre extends StatelessWidget {
  const _Genre({required this.g, required this.bg});
  final Game g;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(g.genre, style: fredoka(11, color: g.color, weight: FontWeight.w500))]),
      );
}
