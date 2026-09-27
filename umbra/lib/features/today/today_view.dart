import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../domain/plan.dart';
import '../../domain/rules.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../account/account_sheet.dart';
import '../memory/memory_detail_sheet.dart';
import '../shell/shell_view.dart';
import '../tell/tell_sheet.dart';
import 'today_view_model.dart';

class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(todayViewModelProvider);
    final vm = ref.read(todayViewModelProvider.notifier);
    final hero = st.hero;
    final more = st.more;

    return ListView(
      padding: EdgeInsets.only(top: 10, bottom: tabBottomPad(context)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(st.dateLabel, style: caps(12))),
              RoundIconButton(icon: UI.chat, label: 'Talk to Umbra', size: 44, iconSize: 18, fg: C.ink, onTap: () => openTellSheet(context)),
              const SizedBox(width: 8),
              Pressable(
                label: 'Account',
                scale: .92,
                onTap: () => openAccountSheet(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: C.ink,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(offset: Offset(0, 8), blurRadius: 16, spreadRadius: -10, color: Color(0xB32B2620))],
                  ),
                  alignment: Alignment.center,
                  child: Text(st.initial, style: serif(19, color: C.paper, height: 1)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '${st.greeting}, '),
                TextSpan(text: '${st.firstName}.', style: serif(42, italic: true, color: C.amber, height: 1, spacing: -.015)),
              ]),
              style: serif(42, height: 1.05, spacing: -.015),
            ),
            const SizedBox(height: 16),
            _SunArc(now: st.now, plan: st.plan),
            const SizedBox(height: 16),
            _Steps(done: st.steps),
          ]),
        ),
        const SizedBox(height: 28),
        _CheckIn(st: st, vm: vm),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Picked '),
                TextSpan(text: 'for you', style: serif(27, italic: true, height: 1.1)),
              ]), style: serif(27, height: 1.1)),
            ),
            if (st.plan.isNotEmpty) Text('${st.plan.length} today', style: sans(12, color: C.muted)),
          ]),
        ),
        const SizedBox(height: 16),
        if (hero != null)
          _HeroCard(key: ValueKey(hero.s.id), p: hero, why: st.ui.whyOpen, vm: vm)
        else
          _PlanEmpty(vm: vm),
        if (more.isNotEmpty) ...[
          const SizedBox(height: 16),
          _LaterToday(items: more, open: st.ui.laterOpen, onToggle: vm.toggleLater, onFocus: vm.focus),
        ],
        if (st.pending.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: easeOutSoft,
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: c)),
              child: st.ui.reviewOpen
                  ? _ReviewOpen(key: const ValueKey('open'), st: st, vm: vm)
                  : _ReviewClosed(key: const ValueKey('closed'), pending: st.pending, onOpen: vm.toggleReview),
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── sun arc ─────────────────────────

class _SunArc extends StatelessWidget {
  const _SunArc({required this.now, required this.plan});
  final DateTime now;
  final List<PlanItem> plan;

  static Offset _pt(double h, double sz) {
    final t = math.pi * (1 - (h.clamp(6, 22) - 6) / 16);
    return Offset((170 + 160 * math.cos(t) - sz / 2).roundToDouble(), (74 - 64 * math.sin(t) - sz / 2).roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final hour = now.hour + now.minute / 60;
    final sun = _pt(hour, 24);
    final marks = plan.where((p) => p.s.hour != null).toList();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 340,
          height: 96,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              top: 0,
              width: 340,
              height: 76,
              child: ClipRect(child: CustomPaint(painter: _ArcPainter(elapsedW: sun.dx + 12))),
            ),
            for (final p in marks)
              Positioned(
                left: _pt(p.s.hour!, 14).dx,
                top: _pt(p.s.hour!, 14).dy,
                child: Tooltip(
                  message: '${p.s.when} · ${p.s.title}',
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: p.s.cbg,
                      shape: BoxShape.circle,
                      border: Border.all(color: C.paper, width: 2.5),
                      boxShadow: const [BoxShadow(offset: Offset(0, 3), blurRadius: 6, spreadRadius: -2, color: Color(0x662B2620))],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: sun.dx,
              top: sun.dy,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: C.sun,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(spreadRadius: 5, color: Color(0x38E9A94A)),
                    BoxShadow(blurRadius: 22, spreadRadius: 6, color: Color(0x59E9A94A)),
                  ],
                ),
              ),
            ),
            if (sun.dx > 44) Positioned(left: 4, top: 82, child: Text('6 AM', style: caps(10, color: C.faint))),
            Positioned(
              left: (sun.dx - 8).clamp(0, 300),
              top: 82,
              width: 40,
              child: Text('NOW', textAlign: TextAlign.center, style: caps(10, color: C.amber)),
            ),
            if (sun.dx < 262) Positioned(right: 4, top: 82, child: Text('10 PM', style: caps(10, color: C.faint))),
          ]),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.elapsedW});
  final double elapsedW;

  @override
  void paint(Canvas canvas, Size size) {
    const oval = Rect.fromLTWH(10, 10, 320, 128);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, elapsedW, size.height));
    canvas.drawOval(oval, Paint()..color = const Color(0x24E9A94A));
    canvas.restore();
    final dash = Paint()
      ..color = C.dash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addOval(oval.deflate(.75));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4.5), dash);
        d += 8;
      }
    }
    canvas.drawRect(Rect.fromLTWH(0, 74, size.width, 1.5), Paint()..color = C.line);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.elapsedW != elapsedW;
}

// ───────────────────────── steps ─────────────────────────

class _Steps extends StatelessWidget {
  const _Steps({required this.done});
  final List<bool> done;

  @override
  Widget build(BuildContext context) {
    const labels = ['Check in', 'Your day', 'Review'];
    final cur = done.indexOf(false);
    final children = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final d = done[i], active = i == cur;
      children.add(Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: d ? C.ink : Colors.transparent,
            shape: BoxShape.circle,
            border: d ? null : Border.all(color: active ? C.ink : C.dash, width: 1.5),
          ),
          alignment: Alignment.center,
          child: d ? const UIcon(UI.check, size: 12, color: C.paper) : Text('${i + 1}', style: sans(11, weight: FontWeight.w600, color: active ? C.ink : C.faint)),
        ),
        const SizedBox(width: 7),
        Text(labels[i], style: sans(12, color: d || active ? C.ink : C.faint)),
      ]));
      if (i < 2) {
        children.add(Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: d ? C.ink : C.line, borderRadius: BorderRadius.circular(1)),
          ),
        ));
      }
    }
    return Row(children: children);
  }
}

// ───────────────────────── check-in ─────────────────────────

class _CheckIn extends StatelessWidget {
  const _CheckIn({required this.st, required this.vm});
  final TodayState st;
  final TodayViewModel vm;

  static UI? _icon(String o) => switch (o) {
        'Rough' => UI.moon,
        'Okay' => UI.halfMoon,
        'Great' => UI.fullMoon,
        'Quiet' => UI.speaker,
        'Calm' => UI.wave,
        'Upbeat' => UI.music,
        'Podcasts' => UI.mic,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final done = st.pulseDone;
    final open = st.checkInExpanded;
    final p = st.pulse;
    final sub = st.checkInSubtitle;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.ink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(offset: Offset(0, 22), blurRadius: 44, spreadRadius: -26, color: Color(0xCC2B2620))],
      ),
      child: Stack(children: [
        const Positioned(
          right: -50,
          top: -70,
          width: 180,
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x17E9A94A), Color(0x00E9A94A)], stops: [0, .7])),
          ),
        ),
        Column(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: done ? vm.toggleCheckIn : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: done ? const Color(0xFF6E9463) : C.sun, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: done ? const UIcon(UI.check, size: 18, color: C.card) : const UIcon(UI.sun, size: 20, color: C.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(done ? 'Checked in' : 'How are you?', style: serif(23, color: C.paper, height: 1.1)),
                    const SizedBox(height: 3),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(12, color: C.onDarkMuted)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
                  decoration: BoxDecoration(color: C.inkSoft, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const UIcon(UI.flame, size: 14, color: C.sun),
                    const SizedBox(width: 5),
                    Text('${st.streak}', style: serif(17, color: C.paper)),
                  ]),
                ),
                if (done) ...[const SizedBox(width: 12), Chevron(open: open, color: C.onDarkMuted)],
              ]),
            ),
          ),
          Reveal(
            open: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: [
                for (final row in pulseRows) ...[
                  _PulseRow(row: row, value: p[row.key], locked: done, onPick: (v) => vm.setPulse(row.key, v)),
                  const SizedBox(height: 14),
                ],
                if (done)
                  Row(children: [
                    Expanded(child: Text(p['sleep'] == 'Rough' ? 'Tonight’s reading is shorter.' : 'Saved for today.', style: sans(12, color: C.onDarkMuted))),
                    Text('+20 XP', style: serif(16, color: C.gold)),
                  ]),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({required this.row, required this.value, required this.locked, required this.onPick});
  final PulseRow row;
  final String? value;
  final bool locked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final energy = row.key == 'energy';
    return Row(children: [
      SizedBox(
        width: 84,
        child: Row(children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: row.glow, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 8, spreadRadius: 1, color: row.glow)]),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(row.label, maxLines: 1, style: sans(13, weight: FontWeight.w500, color: C.onDark)),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Row(children: [
          for (var i = 0; i < row.opts.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _pulseOpt(row.opts[i], energy)),
          ]
        ]),
      ),
    ]);
  }

  Widget _pulseOpt(String o, bool energy) {
    final on = value == o;
    final fg = on ? C.card : C.onDark;
    final icon = _CheckIn._icon(o);
    return Semantics(
      button: true,
      selected: on,
      label: '${row.label} $o',
      child: GestureDetector(
        onTap: locked ? null : () => onPick(o),
        child: AnimatedScale(
          scale: on ? 1.05 : 1,
          duration: const Duration(milliseconds: 250),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 54,
            padding: EdgeInsets.only(bottom: energy ? 12 : 0),
            decoration: BoxDecoration(
              color: on ? row.color : C.inkSoft,
              borderRadius: BorderRadius.circular(16),
              boxShadow: on ? [BoxShadow(offset: const Offset(0, 8), blurRadius: 18, spreadRadius: -8, color: row.color)] : const [],
            ),
            child: Column(mainAxisAlignment: energy ? MainAxisAlignment.end : MainAxisAlignment.center, children: [
              if (energy)
                Container(width: 8, height: 6 + (int.tryParse(o) ?? 0) * 5.0, decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(3)))
              else ...[
                if (icon != null) UIcon(icon, size: 18, color: fg),
                const SizedBox(height: 4),
                Opacity(opacity: .85, child: Text(o, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: sans(10, color: fg))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── picked for you ─────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({super.key, required this.p, required this.why, required this.vm});
  final PlanItem p;
  final bool why;
  final TodayViewModel vm;

  @override
  Widget build(BuildContext context) {
    final g = p.s;
    final open = why && !p.done;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(offset: Offset(0, 18), blurRadius: 40, spreadRadius: -26, color: Color(0x732B2620))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Transform.rotate(
            angle: -2 * math.pi / 180,
            child: Container(
              width: 112,
              height: 164,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
              decoration: BoxDecoration(
                color: g.cbg,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.circular(14)),
                boxShadow: const [
                  BoxShadow(offset: Offset(3, 0), spreadRadius: -1, color: Color(0xFFEFE7D8)),
                  BoxShadow(offset: Offset(6, 1), spreadRadius: -2, color: C.line),
                  BoxShadow(offset: Offset(0, 14), blurRadius: 24, spreadRadius: -12, color: Color(0x8C2B2620)),
                ],
              ),
              foregroundDecoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(6), right: Radius.circular(14)),
                border: Border(left: BorderSide(color: Color(0x24000000), width: 4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Opacity(opacity: .8, child: Text(g.kind.toUpperCase(), style: caps(9, color: g.cfg, spacing: .1))),
                Text(g.title, style: serif(18, color: g.cfg, height: 1.05)),
                Opacity(opacity: .8, child: Text(g.author, style: sans(9, color: g.cfg))),
              ]),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 2),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: C.amberBg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text('Up first · ${g.when}', maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(11, color: C.amber)),
              ),
              const SizedBox(height: 8),
              Text(g.title, style: serif(24, height: 1.1)),
              const SizedBox(height: 8),
              Text(g.sub, style: sans(13, color: C.body, height: 1.4)),
              if (g.prog != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: (double.tryParse(g.prog!.replaceAll('%', '')) ?? 0) / 100, minHeight: 5, color: g.cbg, backgroundColor: C.sand),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(g.prog!, style: sans(11, color: C.muted)),
                ]),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: p.done
              ? Container(
                  key: const ValueKey('done'),
                  height: 52,
                  decoration: BoxDecoration(color: C.greenOk, borderRadius: BorderRadius.circular(26)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const UIcon(UI.check, size: 16, color: C.green, stroke: 2.5),
                    const SizedBox(width: 8),
                    Text(g.doneLabel, style: sans(15, color: C.green)),
                  ]),
                )
              : Row(key: const ValueKey('active'), children: [
                  Expanded(child: PillButton(label: g.cta, onTap: () => vm.start(p))),
                  const SizedBox(width: 8),
                  RoundIconButton(icon: UI.close, label: 'Not now', size: 52, iconSize: 16, bg: Colors.transparent, border: C.line, onTap: () => vm.skip(p)),
                  const SizedBox(width: 8),
                  Pressable(
                    label: 'Why this',
                    scale: .92,
                    onTap: vm.toggleWhy,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: why ? C.ink : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: why ? C.ink : C.line)),
                      alignment: Alignment.center,
                      child: Text('?', style: serif(20, color: why ? C.paper : C.body)),
                    ),
                  ),
                ]),
        ),
        Reveal(
          open: open,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(p.basisText, style: sans(13, color: C.body)),
              for (final m in p.used) ...[
                const SizedBox(height: 8),
                _BasisRow(m: m, onNotTrue: () => vm.notTrue(m.id)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BasisRow extends StatelessWidget {
  const _BasisRow({required this.m, required this.onNotTrue});
  final Memory m;
  final VoidCallback onNotTrue;

  @override
  Widget build(BuildContext context) {
    final L = layerById[m.layer]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(color: L.bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: L.dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openMemorySheet(context, m.id),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(m.text, style: sans(13, height: 1.35))),
          ),
        ),
        const SizedBox(width: 8),
        PillButton(
            label: 'Not true',
            height: 36,
            bg: C.card,
            fg: C.red,
            fontSize: 12,
            weight: FontWeight.w400,
            expand: false,
            padding: 12,
            onTap: onNotTrue),
      ]),
    );
  }
}

class _PlanEmpty extends StatelessWidget {
  const _PlanEmpty({required this.vm});
  final TodayViewModel vm;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DashedBox(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(children: [
            Text('Nothing to suggest yet', textAlign: TextAlign.center, style: serif(22)),
            const SizedBox(height: 14),
            Text('Play a quiz on the You tab and I’ll start planning.', textAlign: TextAlign.center, style: sans(13, color: C.body)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              PillButton(label: 'Play a quiz', height: 44, fontSize: 14, weight: FontWeight.w400, expand: false, padding: 20, onTap: vm.openQuizzes),
              const SizedBox(width: 8),
              PillButton(
                  label: 'Tell me something',
                  height: 44,
                  fontSize: 14,
                  weight: FontWeight.w400,
                  expand: false,
                  padding: 20,
                  bg: C.card,
                  fg: C.ink,
                  onTap: () => openTellSheet(context)),
            ]),
          ]),
        ),
      );
}

class _LaterToday extends StatelessWidget {
  const _LaterToday({required this.items, required this.open, required this.onToggle, required this.onFocus});
  final List<PlanItem> items;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<PlanItem> onFocus;

  @override
  Widget build(BuildContext context) {
    final stack = items.take(4).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0x99FFFDF8), borderRadius: BorderRadius.circular(26)),
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            child: Row(children: [
              OverlapRow(itemWidth: 34, overlap: 14, height: 48, children: [
                for (var i = 0; i < stack.length; i++)
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 350),
                    turns: open ? 0 : (i - 1.5) * 4 / 360,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      offset: Offset(open ? 0 : i * 2 / 34, 0),
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(spreadRadius: 2, color: C.paper)]),
                        child: Cover(bg: stack[i].s.cbg, fg: stack[i].s.cfg, width: 34, height: 44, radiusL: 3, radiusR: 8, glyph: stack[i].s.kind[0]),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Later today', style: serif(18)),
                  const SizedBox(height: 2),
                  Text('${items.length} more · tap to ${open ? 'hide' : 'see the timeline'}', style: sans(12, color: C.muted)),
                ]),
              ),
              Chevron(open: open),
            ]),
          ),
        ),
        Reveal(
          open: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 12, 6),
            child: Column(children: [
              for (var i = 0; i < items.length; i++) _TimelineRow(p: items[i], last: i == items.length - 1, onTap: () => onFocus(items[i])),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.p, required this.last, required this.onTap});
  final PlanItem p;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inferred = p.inferred;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 14,
          child: Column(children: [
            const SizedBox(height: 34),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: inferred ? C.paper : C.ink, shape: BoxShape.circle, border: Border.all(color: inferred ? C.muted : C.ink, width: 2)),
            ),
            const SizedBox(height: 4),
            Expanded(child: Container(width: 2, color: last ? Colors.transparent : C.line)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Pressable(
              onTap: onTap,
              label: p.s.title,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Cover(bg: p.s.cbg, fg: p.s.cfg, width: 48, height: 62, glyph: p.s.kind[0]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.s.when.toUpperCase(), style: caps(10, spacing: .06)),
                      const SizedBox(height: 3),
                      Text(p.s.title, style: serif(18, height: 1.15)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const UIcon(UI.clock, size: 11, color: C.muted),
                        const SizedBox(width: 5),
                        Text(p.done ? '${p.s.mins} · ${p.s.doneLabel.toLowerCase()}' : p.s.mins, style: sans(12, color: C.muted)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────── review ─────────────────────────

(String glyph, Color bg, String line) _srcOf(Pending p) {
  final c = p.conn == null ? null : connById[p.conn];
  final sdef = src[p.source]!;
  return c != null ? (c.glyph, c.color, c.name) : (sdef.code, sdef.color, sdef.name);
}

class _ReviewClosed extends StatelessWidget {
  const _ReviewClosed({super.key, required this.pending, required this.onOpen});
  final List<Pending> pending;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final stack = pending.take(3).toList();
    return Pressable(
      onTap: onOpen,
      label: 'Review',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: C.blueBg, borderRadius: BorderRadius.circular(28)),
        child: Stack(children: [
          const Positioned(
            right: -30,
            bottom: -40,
            width: 120,
            height: 120,
            child: CustomPaint(painter: DashedCirclePainter(color: Color(0x403D5C7A), width: 1.5, dashes: 28)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
            child: Row(children: [
              OverlapRow(itemWidth: 36, overlap: 12, children: [
                for (var i = 0; i < stack.length; i++)
                  Transform.rotate(
                    angle: (i - 1) * 6 * math.pi / 180,
                    child: GlyphTile(glyph: _srcOf(stack[i]).$1, bg: _srcOf(stack[i]).$2, fg: C.card, size: 36, ring: C.blueBg),
                  ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Is this you?', style: serif(21, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(pending.length == 1 ? '1 thing to confirm' : '${pending.length} things to confirm', style: sans(12, color: C.blue)),
                ]),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: C.blue, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text('Review', style: sans(13, color: C.card)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ReviewOpen extends StatefulWidget {
  const _ReviewOpen({super.key, required this.st, required this.vm});
  final TodayState st;
  final TodayViewModel vm;

  @override
  State<_ReviewOpen> createState() => _ReviewOpenState();
}

/// Holds only the edit field's controller; which card is shown and whether it's
/// being edited come from [TodayViewModel].
class _ReviewOpenState extends State<_ReviewOpen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final pend = widget.st.pending;
    final i = widget.st.pendingIndex;
    final p = pend[i];
    final many = pend.length > 1;
    final L = layerById[p.layer]!;
    final editing = widget.st.ui.editing == p.id;
    final (glyph, sbg, sline) = _srcOf(p);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: vm.toggleReview,
              child: Row(children: [
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Is this '),
                  TextSpan(text: 'you?', style: serif(27, italic: true, color: C.blue, height: 1.1)),
                ]), style: serif(27, height: 1.1)),
                const SizedBox(width: 10),
                const Chevron(open: true),
              ]),
            ),
          ),
          if (many)
            Pressable(
              label: 'Next',
              onTap: vm.nextPending,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(border: Border.all(color: C.line), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Text('${i + 1} of ${pend.length}', style: sans(12, color: C.body)),
                  const SizedBox(width: 6),
                  const UIcon(UI.chevRight, size: 11, color: C.body),
                ]),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      Stack(clipBehavior: Clip.none, children: [
        if (many)
          Positioned(
            left: 16,
            right: 16,
            bottom: -9,
            height: 40,
            child: Container(decoration: BoxDecoration(color: const Color(0xFFEDE5D6), borderRadius: BorderRadius.circular(24))),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(.05, 0), end: Offset.zero).animate(a), child: c),
          ),
          child: Container(
            key: ValueKey(p.id),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(offset: Offset(0, 18), blurRadius: 36, spreadRadius: -24, color: Color(0x662B2620))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                GlyphTile(glyph: glyph, bg: sbg, fg: C.card, size: 30, radius: 10, fontSize: 14),
                const SizedBox(width: 10),
                Expanded(child: Text('From $sline', style: sans(12, color: C.muted))),
                if (p.sensitive) const UIcon(UI.lock, size: 12, color: C.teal),
              ]),
              const SizedBox(height: 16),
              Text(p.prompt, style: serif(21, height: 1.3)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: L.bg, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    LayerShape(p.layer, size: 9),
                    const SizedBox(width: 8),
                    Expanded(child: Text(L.plain.toUpperCase(), style: caps(11, color: L.color, spacing: .06))),
                    if (p.layer == 'pattern') ConfDots(p.conf, size: 6, gap: 3),
                    if (p.layer == 'live') Text('Expires in ${expiryDays}d', style: sans(11, color: C.green)),
                  ]),
                  const SizedBox(height: 8),
                  if (!editing)
                    Text(p.text, style: serif(18, height: 1.25))
                  else
                    UField(controller: _text, serifFont: true, fontSize: 16, maxLines: 2, radius: 10, autofocus: true),
                ]),
              ),
              const SizedBox(height: 16),
              if (!editing)
                Row(children: [
                  Expanded(flex: 13, child: PillButton(label: 'Yes, that’s me', height: 50, fontSize: 14, onTap: () => vm.keep(p))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 10,
                    child: PillButton(
                        label: 'Not me', height: 50, fontSize: 14, weight: FontWeight.w400, bg: Colors.transparent, fg: C.ink, border: C.line, onTap: () => vm.reject(p)),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: UI.edit,
                    label: 'Edit',
                    size: 50,
                    iconSize: 16,
                    bg: Colors.transparent,
                    border: C.line,
                    onTap: () {
                      _text.text = p.text;
                      vm.startEdit(p);
                    },
                  ),
                ])
              else
                Row(children: [
                  Expanded(
                    child: PillButton(
                      label: 'Keep edited',
                      height: 50,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      onTap: () => vm.keep(p, _text.text),
                    ),
                  ),
                  TextLink('Cancel', height: 50, onTap: vm.cancelEdit),
                  const SizedBox(width: 8),
                ]),
            ]),
          ),
        ),
      ]),
    ]);
  }
}
