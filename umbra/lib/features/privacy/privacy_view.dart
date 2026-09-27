import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../shell/shell_view.dart';
import 'mech_row.dart';
import 'permissions_view_model.dart';
import 'privacy_view_model.dart';

class PrivacyView extends ConsumerWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(privacyViewModelProvider);
    final vm = ref.read(privacyViewModelProvider.notifier);
    final liveConns = s.liveConns;
    final srcCounts = s.bySource;
    bool open(String k) => s.open.contains(k);
    Rect? originOf(BuildContext c) {
      final box = c.findRenderObject() as RenderBox?;
      return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    }

    Color srcFill(String k) => k == 'explicit' ? C.onDark : src[k]!.color;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, tabBottomPad(context)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'Your data, '),
            TextSpan(text: 'your call', style: serif(38, italic: true, color: C.teal, height: 1, spacing: -.015)),
          ]), style: serif(38, height: 1, spacing: -.015)),
        ),
        const SizedBox(height: 14),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: C.ink,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(offset: Offset(0, 24), blurRadius: 44, spreadRadius: -26, color: Color(0xCC2B2620))],
          ),
          child: Stack(children: [
            Positioned(
              left: -40,
              bottom: -60,
              width: 160,
              height: 160,
              child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x249FC3C1)))),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(spreadRadius: 6, color: C.inkSoft)]),
                  child: Donut(
                    size: 124,
                    thickness: 17,
                    empty: C.inkSoft,
                    segments: [for (final k in mechOrder) (srcCounts[k]!.toDouble(), srcFill(k))],
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const UIcon(UI.shield, size: 16, color: C.tealLight),
                      const SizedBox(height: 3),
                      Text('${s.memories}', style: serif(26, color: C.paper, height: 1)),
                      const SizedBox(height: 3),
                      Text('KEPT', style: caps(9, color: C.onDarkMuted, spacing: .12)),
                    ]),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(children: [
                    for (final k in mechOrder)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Opacity(
                          opacity: srcCounts[k]! > 0 ? 1 : .4,
                          child: Row(children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: srcFill(k),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0x26FFFDF8)),
                              ),
                              alignment: Alignment.center,
                              child: Text(src[k]!.code, style: serif(11, color: k == 'explicit' ? C.ink : C.card, height: 1)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(src[k]!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(11, color: C.onDark))),
                            Text('${srcCounts[k]}', style: serif(14, color: C.paper)),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: C.tealBg, borderRadius: BorderRadius.circular(26)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: C.teal, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const UIcon(UI.lock, size: 18, color: C.card, stroke: 1.8),
                    ),
                    UToggle(on: s.healthExport, springy: true, label: 'Include health in exports', onTap: vm.toggleHealthExport),
                  ]),
                  const SizedBox(height: 14),
                  Text('Health', style: serif(19, color: const Color(0xFF1F4E51), height: 1.1)),
                  const SizedBox(height: 2),
                  Text(s.healthExport ? 'In exports' : 'Kept out of exports', style: sans(11, color: C.teal)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Pressable(
                onTap: vm.openSources,
                label: 'Apps',
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(26)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      height: 44,
                      child: Row(children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: OverlapRow(itemWidth: 30, overlap: 12, children: [
                              for (final c in liveConns.take(4)) GlyphTile(glyph: c.glyph, bg: c.color, fg: c.fg, size: 30, radius: 10, fontSize: 13, ring: C.card, ringWidth: 2),
                            ]),
                          ),
                        ),
                        const UIcon(UI.chevRight, size: 13, color: C.muted, stroke: 2.3),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text('Apps', style: serif(19, height: 1.1)),
                    const SizedBox(height: 2),
                    Text('${liveConns.length} of ${conns.length} sharing', style: sans(11, color: C.muted)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _Section(
          open: open('learn'),
          onToggle: () => vm.toggleSection('learn'),
          icon: UI.sliders,
          iconBg: C.amberBg,
          iconFg: C.amber,
          title: 'How I learn',
          summary: '${s.mechOn} of 5 on',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final k in mechOrder) ...[
              const SizedBox(width: 3),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: (s.mech[k] ?? false) ? src[k]!.color : C.line, shape: BoxShape.circle)),
            ],
          ]),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(children: [
              const _LearnRows(),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          open: open('export'),
          onToggle: () => vm.toggleSection('export'),
          icon: UI.download,
          iconBg: C.blueBg,
          iconFg: C.blue,
          title: 'Take it with you',
          summary: 'Every item, with its history',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(
                child: Builder(
                  builder: (bc) => _ExportTile(
                    bg: C.ink,
                    fg: C.paper,
                    glyph: Text('{ }', style: serif(20, color: C.paper)),
                    label: 'JSON',
                    onTap: () => vm.export(json: true, origin: originOf(bc)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (bc) => _ExportTile(
                    bg: C.blueBg,
                    fg: C.blue,
                    glyph: const UIcon(UI.doc, size: 20, color: C.blue),
                    label: 'Summary',
                    onTap: () => vm.export(json: false, origin: originOf(bc)),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          open: open('forget'),
          onToggle: () => vm.toggleSection('forget'),
          icon: UI.trash,
          iconBg: C.redBg,
          iconFg: C.red,
          title: 'Forget',
          summary: 'By layer, or everything',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                for (final (i, L) in layers.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _ForgetTile(L: L, n: s.byLayer[L.id]!, onTap: () => vm.forgetLayer(L.id))),
                ],
              ]),
              const SizedBox(height: 10),
              PillButton(
                label: 'Forget everything',
                height: 48,
                fontSize: 14,
                weight: FontWeight.w400,
                bg: Colors.transparent,
                fg: C.red,
                border: const Color(0xFFE7C6BC),
                icon: const UIcon(UI.trash, size: 14, color: C.red),
                onTap: () => _confirmForgetAll(context, s, vm),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          open: open('recent'),
          onToggle: () => vm.toggleSection('recent'),
          icon: UI.clock,
          iconBg: const Color(0xFFEAE2D3),
          iconFg: C.ink,
          title: 'Activity',
          summary: s.log.isNotEmpty ? s.log.first.text : 'Nothing yet',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 16, 10),
            child: Column(children: [
              for (final (i, l) in s.log.indexed)
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 10,
                      child: Column(children: [
                        const SizedBox(height: 14),
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: i == 0 ? C.ink : C.dash, shape: BoxShape.circle)),
                        Expanded(child: Container(width: 1.5, color: i == s.log.length - 1 ? Colors.transparent : C.line)),
                      ]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(dayLabel(l.at, s.now).toUpperCase(), style: caps(10, spacing: .06)),
                          const SizedBox(height: 2),
                          Text(l.text, style: sans(13, height: 1.4)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              if (s.log.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text('Nothing yet', style: sans(13, color: C.muted))),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        PillButton(
          label: 'Sign out',
          height: 52,
          fontSize: 14,
          weight: FontWeight.w400,
          bg: Colors.transparent,
          fg: C.body,
          icon: const UIcon(UI.signOut, size: 16, color: C.body),
          onTap: vm.signOut,
        ),
      ],
    );
  }

  Future<void> _confirmForgetAll(BuildContext context, PrivacyState s, PrivacyViewModel vm) async {
    if (!s.hasAnything) return;
    final ok = await showUmbraSheet<bool>(
      context,
      (c) => SheetFrame(children: [
        Text('Forget everything?', style: serif(26)),
        Text('All ${plural(s.memories, 'memory', 'memories')} and pending suggestions will be deleted. You can undo for a few seconds.',
            style: sans(14, color: C.body, height: 1.45)),
        Row(children: [
          Expanded(child: PillButton(label: 'Forget everything', bg: C.red, fg: C.card, onTap: () => Navigator.pop(c, true))),
          const SizedBox(width: 8),
          TextLink('Cancel', onTap: () => Navigator.pop(c, false)),
          const SizedBox(width: 12),
        ]),
      ]),
    );
    if (ok == true) vm.forgetAll();
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.open,
    required this.onToggle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.summary,
    required this.child,
    this.trailing,
  });
  final bool open;
  final VoidCallback onToggle;
  final UI icon;
  final Color iconBg, iconFg;
  final String title, summary;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: open ? const [BoxShadow(offset: Offset(0, 16), blurRadius: 32, spreadRadius: -22, color: Color(0x802B2620))] : const [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(children: [
                AnimatedRotation(
                  turns: open ? -8 / 360 : 0,
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: UIcon(icon, size: 20, color: iconFg),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: serif(20, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(12, color: C.muted)),
                  ]),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                const SizedBox(width: 14),
                Chevron(open: open),
              ]),
            ),
          ),
          Reveal(open: open, child: child),
        ]),
      );
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({required this.bg, required this.fg, required this.glyph, required this.label, required this.onTap});
  final Color bg, fg;
  final Widget glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        label: 'Export $label',
        child: Container(
          height: 84,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            glyph,
            const SizedBox(height: 6),
            Text(label, style: sans(12, color: fg)),
          ]),
        ),
      );
}

class _ForgetTile extends StatelessWidget {
  const _ForgetTile({required this.L, required this.n, required this.onTap});
  final LayerDef L;
  final int n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: n > 0 ? onTap : null,
        label: 'Forget ${L.name}',
        scale: .95,
        child: Opacity(
          opacity: n > 0 ? 1 : .45,
          child: Container(
            height: 84,
            decoration: BoxDecoration(color: L.bg, borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              LayerShape(L.id),
              const SizedBox(height: 6),
              Text('$n', style: serif(22, color: L.color, height: 1)),
              const SizedBox(height: 6),
              Text(L.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(10, color: L.color)),
            ]),
          ),
        ),
      );
}

class _LearnRows extends ConsumerWidget {
  const _LearnRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(permissionsViewModelProvider);
    final vm = ref.read(permissionsViewModelProvider.notifier);
    return Column(children: [
      for (final r in rows)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.sand))),
          child: MechRow(row: r, compact: true, onToggle: () => vm.toggle(r.key), onForget: () => vm.forget(r.key)),
        ),
    ]);
  }
}
