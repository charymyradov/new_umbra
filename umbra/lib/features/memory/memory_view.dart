import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../domain/rules.dart';
import '../../widgets/common.dart';
import '../../widgets/domain_badge.dart';
import '../../widgets/icons.dart';
import '../shell/shell_view.dart';
import 'memory_detail_sheet.dart';
import 'memory_view_model.dart';

class MemoryView extends ConsumerStatefulWidget {
  const MemoryView({super.key});

  @override
  ConsumerState<MemoryView> createState() => _MemoryViewState();
}

/// Owns the search/add text controllers; filters, disclosure and data come from [MemoryViewModel].
class _MemoryViewState extends ConsumerState<MemoryView> {
  late final _q = TextEditingController(text: ref.read(memoryViewModelProvider).query);
  final _add = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    _add.dispose();
    super.dispose();
  }

  MemoryViewModel get _vm => ref.read(memoryViewModelProvider.notifier);

  void _toggleSearch() {
    if (ref.read(memoryViewModelProvider).searchOpen) _q.clear();
    _vm.toggleSearch();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(memoryViewModelProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, tabBottomPad(context)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: 'What I know '),
                TextSpan(text: 'about you', style: serif(38, italic: true, color: C.blue, height: 1, spacing: -.015)),
              ]), style: serif(38, height: 1, spacing: -.015)),
            ),
            const SizedBox(width: 12),
            RoundIconButton(
              icon: UI.search,
              label: 'Search',
              size: 44,
              iconSize: 17,
              bg: s.searchOpen ? C.ink : C.card,
              fg: s.searchOpen ? C.paper : C.ink,
              shadows: const [BoxShadow(offset: Offset(0, 6), blurRadius: 14, spreadRadius: -8, color: Color(0x662B2620))],
              onTap: _toggleSearch,
            ),
          ]),
        ),
        Reveal(
          open: s.searchOpen,
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(25), border: Border.all(color: C.line, width: 1.5)),
              child: Row(children: [
                const UIcon(UI.search, size: 16, color: C.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _q,
                    onChanged: _vm.setQuery,
                    style: sans(15),
                    decoration: InputDecoration.collapsed(hintText: 'Search', hintStyle: sans(15, color: C.muted)),
                  ),
                ),
                if (s.query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _q.clear();
                      _vm.setQuery('');
                    },
                    child: const UIcon(UI.close, size: 12, color: C.muted),
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _Overview(st: s, vm: _vm),
        const SizedBox(height: 22),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              for (final d in [const Domain('all', 'All', C.muted, C.sand, ''), ...domains, coreDomain]) ...[
                _DomChip(d: d, on: s.domF == d.id, onTap: () => _vm.setDomain(d.id)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        for (final sec in s.sections) ...[
          const SizedBox(height: 22),
          _LayerSection(sec: sec, vm: _vm, addCtl: _add, onStartAdd: () {
            _add.clear();
            _vm.startAdd(sec.layer.id);
          }),
        ],
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.st, required this.vm});
  final MemoryState st;
  final MemoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = st;
    final open = st.overviewOpen;
    final counts = st.counts;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.ink,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(offset: Offset(0, 28), blurRadius: 48, spreadRadius: -28, color: Color(0xD92B2620))],
      ),
      child: Stack(children: [
        const Positioned(
          right: -70,
          top: -70,
          width: 260,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x1AE9C98A), Color(0x00E9C98A)], stops: [0, .65])),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Pressable(
              onTap: vm.toggleOverview,
              scale: .98,
              label: 'Toggle memory overview',
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('YOUR MEMORY', style: caps(10, color: C.onDarkMuted, spacing: .16)),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(color: Color(0x14FFFDF8), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: AnimatedRotation(
                          turns: open ? .5 : 0,
                          duration: const Duration(milliseconds: 550),
                          curve: easeSpringStrong,
                          child: const UIcon(UI.chevDown, size: 10, color: C.gold, stroke: 3),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text('${s.total}', style: serif(64, color: C.paper, height: .95, spacing: -.03)),
                      const SizedBox(width: 10),
                      Text('things', style: serif(19, italic: true, color: C.gold)),
                    ]),
                  ]),
                ),
                AnimatedRotation(
                  turns: open ? .5 : 0,
                  duration: const Duration(milliseconds: 800),
                  curve: easeSpring,
                  child: AnimatedScale(
                    scale: open ? 1 : .88,
                    duration: const Duration(milliseconds: 800),
                    curve: easeSpring,
                    child: SizedBox.square(
                      dimension: 96,
                      child: Stack(children: [
                        for (final L in layers)
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.all(L.ringInset),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 350),
                                opacity: s.filter != 'all' && s.filter != L.id ? .25 : 1,
                                child: L.id == 'live'
                                    ? CustomPaint(painter: DashedCirclePainter(color: L.dark, width: s.filter == L.id ? 2.5 : 1.5, dashes: 30))
                                    : Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: L.dark, width: s.filter == L.id ? 2.5 : 1.5))),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(42),
                            child: Container(
                              decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 12, spreadRadius: 2, color: Color(0x73E9C98A))]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            TweenAnimationBuilder<double>(
              tween: Tween(end: open ? 1 : 0),
              duration: const Duration(milliseconds: 500),
              curve: easeSpring,
              builder: (_, t, _) => SizedBox(
                height: 6 + 2 * t,
                child: Row(children: [
                  for (var i = 0; i < layers.length; i++) ...[
                    if (i > 0) SizedBox(width: 3 + t),
                    Expanded(
                      flex: ((counts[layers[i].id]! == 0 ? .3 : counts[layers[i].id]!.toDouble()) * 10).round(),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 350),
                        opacity: s.filter != 'all' && s.filter != layers[i].id ? .25 : 1,
                        child: Container(decoration: BoxDecoration(color: layers[i].dark, borderRadius: BorderRadius.circular(3))),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            Reveal(
              open: open,
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.75,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < layers.length; i++)
                      PopIn(delay: Duration(milliseconds: 70 * i), child: _OvTile(L: layers[i], count: counts[layers[i].id]!, st: st, vm: vm)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _OvTile extends StatelessWidget {
  const _OvTile({required this.L, required this.count, required this.st, required this.vm});
  final LayerDef L;
  final int count;
  final MemoryState st;
  final MemoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final sel = st.filter == L.id;
    final dim = st.dimmed(L.id);
    return Pressable(
      onTap: () => vm.setFilter(L.id),
      label: L.plain,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? const Color(0x1AFFFDF8) : const Color(0x09FFFDF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? L.dark : const Color(0x12FFFDF8)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: sel ? const Color(0x1FFFFDF8) : const Color(0x0FFFFDF8), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: UIcon(UI.forLayer(L.id), size: 15, color: L.dark),
            ),
            Text('$count', style: serif(26, color: C.paper, height: 1)),
          ]),
          Text(L.plain, style: sans(12, color: dim ? C.muted : const Color(0xFFD9D0C1), spacing: .01)),
        ]),
      ),
    );
  }
}

class _DomChip extends StatelessWidget {
  const _DomChip({required this.d, required this.on, required this.onTap});
  final Domain d;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = on ? (d.id == 'all' ? C.ink : d.color) : C.card;
    return Pressable(
      onTap: onTap,
      label: d.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 42,
        padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(21),
          boxShadow: on ? [BoxShadow(offset: const Offset(0, 8), blurRadius: 16, spreadRadius: -10, color: d.color)] : const [],
        ),
        child: Row(children: [
          DomainBadge(d.id, size: 30, iconSize: 14, bg: on ? const Color(0x2EFFFDF8) : d.bg, fg: on ? C.card : d.color),
          const SizedBox(width: 8),
          Text(d.name, style: sans(13, color: on ? C.card : C.ink)),
        ]),
      ),
    );
  }
}

class _LayerSection extends StatelessWidget {
  const _LayerSection({required this.sec, required this.vm, required this.addCtl, required this.onStartAdd});
  final LayerSection sec;
  final MemoryViewModel vm;
  final TextEditingController addCtl;
  final VoidCallback onStartAdd;

  @override
  Widget build(BuildContext context) {
    final L = sec.layer;
    final items = sec.items;
    final open = sec.open;
    final adding = sec.adding;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Pressable(
            onTap: () => vm.toggleLayer(L.id),
            scale: .98,
            label: L.plain,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: open ? const [BoxShadow(offset: Offset(0, 10), blurRadius: 24, spreadRadius: -16, color: Color(0x732B2620))] : const [],
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: L.bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: UIcon(UI.forLayer(L.id), size: 19, color: L.color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(L.plain, style: serif(21, height: 1.1))),
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: L.bg, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text('${items.length}', style: sans(12, color: L.color, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Chevron(open: open),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Pressable(
          onTap: onStartAdd,
          scale: .92,
          label: 'Add to ${L.name}',
          child: SizedBox.square(
            dimension: 44,
            child: CustomPaint(
              painter: DashedCirclePainter(color: L.color.withValues(alpha: .33), dashes: 18),
              child: Center(child: UIcon(UI.plus, size: 15, color: L.color)),
            ),
          ),
        ),
      ]),
      Reveal(
        open: adding,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: L.color, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              UField(controller: addCtl, hint: L.addPh, serifFont: true, fontSize: 16, maxLines: 2, bg: L.bg, radius: 12, autofocus: adding),
              const SizedBox(height: 10),
              Text(sec.addNote, style: sans(12, color: C.muted)),
              const SizedBox(height: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: addCtl,
                builder: (_, v, _) => Row(children: [
                  Expanded(
                    child: PillButton(
                      label: 'Save',
                      height: 44,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      enabled: v.text.trim().isNotEmpty,
                      onTap: () => vm.add(L.id, addCtl.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextLink('Cancel', onTap: vm.cancelAdd),
                  const SizedBox(width: 8),
                ]),
              ),
            ]),
          ),
        ),
      ),
      Reveal(
        open: open,
        child: items.isEmpty
            ? (adding
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(left: 43, top: 10),
                    child: Pressable(
                      onTap: onStartAdd,
                      child: DashedBox(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          UIcon(UI.plus, size: 13, color: L.color),
                          const SizedBox(width: 8),
                          Text(sec.emptyLabel, style: sans(13, color: L.color)),
                        ]),
                      ),
                    ),
                  ))
            : Padding(
                padding: const EdgeInsets.only(left: 31, top: 10),
                child: Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: L.bg, width: 2))),
                  child: Column(children: [
                    for (final it in items) ...[
                      MemoryTile(item: it, onStill: () => vm.reconfirm(it.m.id), onNoLonger: () => vm.forget(it.m.id)),
                      const SizedBox(height: 6),
                    ],
                  ]),
                ),
              ),
      ),
    ]);
  }
}

/// One memory row with its layer-specific trailing (confidence bars or days-left ring).
class MemoryTile extends StatelessWidget {
  const MemoryTile({super.key, required this.item, required this.onStill, required this.onNoLonger});
  final MemoryItem item;
  final VoidCallback onStill, onNoLonger;

  @override
  Widget build(BuildContext context) {
    final m = item.m;
    final meta = item.meta;
    final stale = item.stale;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Pressable(
          onTap: () => openMemorySheet(context, m.id),
          scale: .98,
          label: m.text,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              DomainBadge(m.dom),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.text, style: serif(17, height: 1.28)),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (m.sensitive) ...[const UIcon(UI.lock, size: 11, color: C.teal), const SizedBox(width: 5)],
                    Expanded(child: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(11, color: C.muted))),
                  ]),
                ]),
              ),
              if (m.layer == 'pattern' && m.confidence != null) ...[
                const SizedBox(width: 8),
                _ConfBars(m.confidence!),
              ],
              if (m.layer == 'live') ...[
                const SizedBox(width: 8),
                Ring(
                  pct: item.daysLeft / expiryDays,
                  color: C.green,
                  track: const Color(0xFFD5E0CB),
                  size: 36,
                  thickness: 4,
                  child: Text('${item.daysLeft}d', style: serif(13, color: C.green, height: 1)),
                ),
              ],
            ]),
          ),
        ),
        if (stale)
          Container(
            color: C.staleBg,
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(children: [
              Expanded(child: Text('Still true?', style: sans(13, color: C.amber))),
              PillButton(label: 'Yes', height: 34, bg: C.card, fg: C.ink, fontSize: 13, weight: FontWeight.w400, expand: false, padding: 14, onTap: onStill),
              TextLink('No', color: C.red, size: 13, height: 34, onTap: onNoLonger),
              const SizedBox(width: 10),
            ]),
          ),
      ]),
    );
  }
}

class _ConfBars extends StatelessWidget {
  const _ConfBars(this.conf);
  final double conf;

  @override
  Widget build(BuildContext context) {
    final n = (conf * 5).round();
    return SizedBox(
      height: 18,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(width: 4, height: 6 + i * 3.0, decoration: BoxDecoration(color: i < n ? C.blue : const Color(0xFFD3DDE7), borderRadius: BorderRadius.circular(2))),
        ],
      ]),
    );
  }
}
