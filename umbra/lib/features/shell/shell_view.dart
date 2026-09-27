import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/icons.dart';
import '../games/games_view.dart';
import '../memory/memory_view.dart';
import '../privacy/privacy_view.dart';
import '../privacy/sources_view.dart';
import '../today/today_view.dart';
import '../you/you_view.dart';
import 'shell_view_model.dart';

class ShellView extends ConsumerWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellState(:tab, :dir) = ref.watch(shellViewModelProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBottom = math.max(bottomInset, 10.0) + 12;
    return Scaffold(
      backgroundColor: C.paper,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: _TabEntrance(
              key: ValueKey(tab),
              dir: dir,
              child: switch (tab) {
                'today' => const TodayView(),
                'memory' => const MemoryView(),
                'you' => const YouView(),
                'sources' => const SourcesView(),
                'privacy' => const PrivacyView(),
                _ => const GamesView(),
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 96 + bottomInset,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00F6F1E7), C.paper],
                  stops: [0, .4],
                ),
              ),
            ),
          ),
        ),
        Positioned(left: 14, right: 14, bottom: navBottom, height: 64, child: const _NavBar()),
      ]),
    );
  }
}

/// Bottom padding every tab's scroll view needs to clear the floating nav.
double tabBottomPad(BuildContext context) => 110 + MediaQuery.of(context).padding.bottom;

/// Slide + fade in on mount; direction follows tab order (like the CSS tabInR/tabInL keyframes).
class _TabEntrance extends StatefulWidget {
  const _TabEntrance({super.key, required this.dir, required this.child});
  final int dir;
  final Widget child;

  @override
  State<_TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<_TabEntrance> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  late final _a = CurvedAnimation(parent: _c, curve: easeOutSoft);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final begin = widget.dir == 0 ? const Offset(0, 14) : Offset(28.0 * widget.dir, 0);
    return AnimatedBuilder(
      animation: _a,
      child: RepaintBoundary(child: widget.child),
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset.lerp(begin, Offset.zero, _a.value)!, child: child),
      ),
    );
  }
}

class _NavBar extends ConsumerWidget {
  const _NavBar();

  static const _shadows = [
    BoxShadow(offset: Offset(0, 18), blurRadius: 36, spreadRadius: -18, color: Color(0x732B2620)),
    BoxShadow(offset: Offset(0, 4), blurRadius: 10, spreadRadius: -6, color: Color(0x262B2620)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellViewModelProvider);
    final badge = ref.watch(todayBadgeProvider);
    final vm = ref.read(shellViewModelProvider.notifier);
    Widget item(String id, String label, UI icon, {bool dot = false}) {
      final b = _NavButton(label: label, icon: icon, on: shell.isOn(id), badge: dot, onTap: () => vm.goTab(id));
      return shell.isOn(id) ? Flexible(child: b) : b;
    }

    return Row(children: [
      Expanded(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: const Color(0xEBFFFDF8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xB3E4DBCB)),
            boxShadow: _shadows,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            item('today', 'Today', UI.navToday, dot: badge),
            item('memory', 'Memory', UI.navMemory),
            item('you', 'You', UI.navYou),
            item('privacy', 'Privacy', UI.shieldCheck),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      _SetirButton(on: shell.tab == 'setir', onTap: () => vm.goTab('setir')),
    ]);
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({required this.label, required this.icon, required this.on, required this.badge, required this.onTap});
  final String label;
  final UI icon;
  final bool on, badge;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    final fg = on ? C.paper : C.muted;
    return Semantics(
      button: true,
      selected: on,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? .92 : 1,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeOutSoft,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: on ? C.ink : const Color(0x002B2620),
              borderRadius: BorderRadius.circular(24),
              boxShadow: on ? const [BoxShadow(offset: Offset(0, 8), blurRadius: 18, spreadRadius: -8, color: Color(0x992B2620))] : const [],
            ),
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedScale(
                  scale: on ? 1 : .94,
                  duration: const Duration(milliseconds: 450),
                  curve: const Cubic(.3, 1.7, .5, 1),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: fg),
                    duration: const Duration(milliseconds: 350),
                    builder: (_, c, _) => UIcon(widget.icon, size: 22, color: c ?? fg),
                  ),
                ),
                Flexible(
                  child: ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: easeOutSoft,
                      alignment: Alignment.centerLeft,
                      child: on
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(widget.label, maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: sans(13, color: C.paper, weight: FontWeight.w500, spacing: .01)),
                            )
                          : const SizedBox(height: 1),
                    ),
                  ),
                ),
              ]),
              if (widget.badge)
                Positioned(
                  top: -4,
                  left: 15,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: const Color(0xFFC0772E), shape: BoxShape.circle, border: Border.all(color: C.card, width: 2)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SetirButton extends StatelessWidget {
  const _SetirButton({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  String _svg(bool on) {
    final stroke = on ? '#F6F1E7' : '#8A8174';
    String f(String c) => on ? c : 'none';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">'
        '<circle cx="7.5" cy="7.5" r="3.5" fill="${f('#F2A93B')}"/><rect x="13" y="4" width="7" height="7" rx="2" fill="${f('#E5476A')}"/>'
        '<rect x="4" y="13" width="7" height="7" rx="2" fill="${f('#2F72C9')}"/><path d="M16.5 13.2l3.6 6.3h-7.2z" fill="${f('#2F8F4E')}"/></svg>';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: on,
          label: 'setir games',
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xEBFFFDF8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xB3E4DBCB)),
              boxShadow: _NavBar._shadows,
            ),
            alignment: Alignment.center,
            child: AnimatedRotation(
              turns: on ? -12 / 360 : 0,
              duration: const Duration(milliseconds: 550),
              curve: const Cubic(.3, 1.7, .5, 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: on ? C.ink : const Color(0x002B2620), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SetirGlyph(key: ValueKey(on), svg: _svg(on)),
                ),
              ),
            ),
          ),
        ),
      );
}
