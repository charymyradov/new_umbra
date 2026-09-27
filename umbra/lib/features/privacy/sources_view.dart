import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../shell/shell_view.dart';
import 'folder_sheet.dart';
import 'privacy_view_model.dart';

// ───────────────────────── connected apps ─────────────────────────

class SourcesView extends ConsumerWidget {
  const SourcesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sourcesViewModelProvider);
    final vm = ref.read(sourcesViewModelProvider.notifier);
    final live = s.liveConns;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, tabBottomPad(context)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pressable(
              onTap: vm.back,
              label: 'Back to Privacy',
              child: Container(
                height: 34,
                padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(17)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const UIcon(UI.back, size: 12, color: C.body, stroke: 2.5),
                  const SizedBox(width: 6),
                  Text('Privacy', style: sans(13, color: C.body)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text('Connected apps', style: serif(32, height: 1.05)),
            const SizedBox(height: 6),
            Text('Optional. ${live.length} of ${conns.length} on. Umbra works fully without them.', style: sans(14, color: C.body)),
          ]),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24)),
          child: Row(children: [
            SizedBox(
              height: 42,
              child: OverlapRow(itemWidth: 38, overlap: 12, children: [
                for (final c in live.take(5)) GlyphTile(glyph: c.glyph, bg: c.color, fg: c.fg, size: 38, ring: C.card),
              ]),
            ),
            if (live.isNotEmpty) const SizedBox(width: 14),
            Expanded(
              child: Text(
                s.stackLabel,
                style: sans(13, color: C.body, height: 1.35),
              ),
            ),
          ]),
        ),
        if (s.linked.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: SectionLabel('APPS USING YOUR UMBRA ACCOUNT')),
          const SizedBox(height: 10),
          for (final l in s.linked) ...[
            _LinkedTile(l: l, onDisconnect: () => vm.disconnect(l.id)),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 22),
        for (var i = 0; i < s.folders.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _FolderTile(sum: s.folders[i])),
            const SizedBox(width: 12),
            Expanded(child: i + 1 < s.folders.length ? _FolderTile(sum: s.folders[i + 1]) : const SizedBox.shrink()),
          ]),
        ],
      ],
    );
  }
}

class _LinkedTile extends StatelessWidget {
  const _LinkedTile({required this.l, required this.onDisconnect});
  final LinkedSummary l;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          GlyphTile(glyph: l.glyph, bg: C.ink, fg: C.paper, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name, style: sans(15, weight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text('Since ${l.since} · ${l.shares}', style: sans(12.5, color: C.muted, height: 1.35)),
            ]),
          ),
          TextLink('Disconnect', color: C.red, size: 13, onTap: onDisconnect),
        ]),
      );
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.sum});
  final FolderSummary sum;

  Widget _mini(Conn? c) => c == null
      ? Container(decoration: BoxDecoration(color: const Color(0x73FFFDF8), borderRadius: BorderRadius.circular(14)))
      : AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: sum.live.contains(c.id) ? 1 : .3,
          child: Container(
            decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(c.glyph, style: serif(20, color: c.fg, height: 1)),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final f = sum.folder;
    final apps = sum.apps;
    final on = sum.onCount;
    return Pressable(
      onTap: () => openFolderSheet(context, f.id),
      label: f.name,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: f.bg, borderRadius: BorderRadius.circular(30)),
            child: Column(children: [
              for (var r = 0; r < 2; r++) ...[
                if (r > 0) const SizedBox(height: 10),
                Expanded(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (var c = 0; c < 2; c++) ...[
                      if (c > 0) const SizedBox(width: 10),
                      Expanded(child: _mini(r * 2 + c < apps.length ? apps[r * 2 + c] : null)),
                    ],
                  ]),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name, style: sans(15, weight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(on > 0 ? '$on of ${apps.length} on' : 'Off', style: sans(12, color: C.muted)),
          ]),
        ),
      ]),
    );
  }
}
