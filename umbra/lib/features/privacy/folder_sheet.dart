import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import 'folder_view_model.dart';

Future<void> openFolderSheet(BuildContext context, String folder) => showUmbraSheet(context, (_) => FolderSheet(folder: folder));

/// A folder of connected apps: list with toggles, then per-app detail (reads / never reads).
class FolderSheet extends ConsumerWidget {
  const FolderSheet({super.key, required this.folder});
  final String folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(folderViewModelProvider(folder));
    final vm = ref.read(folderViewModelProvider(folder).notifier);
    final app = st.app;
    return SheetFrame(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: Offset(app == null ? -.05 : .05, 0), end: Offset.zero).animate(a), child: c),
        ),
        child: app == null ? _list(context, st, vm) : _detail(context, st, vm, app),
      ),
    ]);
  }

  Widget _list(BuildContext context, FolderState st, FolderViewModel vm) => Column(
        key: const ValueKey('list'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              Expanded(child: Text(st.folder.name, style: serif(28))),
              RoundIconButton(icon: UI.close, label: 'Close', onTap: () => Navigator.pop(context)),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              for (final (i, row) in st.apps.indexed)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => vm.open(row.conn.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    decoration: BoxDecoration(border: i > 0 ? const Border(top: BorderSide(color: C.sand)) : null),
                    child: Row(children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: row.live ? 1 : .4,
                        child: GlyphTile(glyph: row.conn.glyph, bg: row.conn.color, fg: row.conn.fg, size: 48, radius: 14, fontSize: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(row.conn.name, style: sans(15, weight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(row.status, style: sans(12, color: C.muted)),
                        ]),
                      ),
                      UToggle(on: row.on, label: row.conn.name, onTap: () => vm.toggle(row.conn.id)),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
      );

  Widget _detail(BuildContext context, FolderState st, FolderViewModel vm, AppRowState row) {
    final c = row.conn, on = row.on, mechOn = row.mechOn, n = row.memories;
    final f = st.folder;
    final sd = row.mechanism;
    Widget chips(String title, UI icon, Color color, List<String> items, Color textColor) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [UIcon(icon, size: 14, color: color, stroke: 2.5), const SizedBox(width: 6), Text(title, style: sans(12, color: color))]),
            for (final t in items) ...[const SizedBox(height: 10), Text(t, style: sans(13, color: textColor, height: 1.3))],
          ]),
        );
    return Column(
      key: ValueKey(c.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Pressable(
            onTap: vm.back,
            label: 'Back to ${f.name}',
            child: Container(
              height: 34,
              padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(17)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const UIcon(UI.back, size: 12, color: C.body, stroke: 2.5),
                const SizedBox(width: 6),
                Text(f.name, style: sans(13, color: C.body)),
              ]),
            ),
          ),
          const Spacer(),
          RoundIconButton(icon: UI.close, label: 'Close', onTap: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 22),
        Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: on && mechOn ? 1 : .4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(offset: Offset(0, 14), blurRadius: 28, spreadRadius: -14, color: Color(0x802B2620))],
              ),
              child: GlyphTile(glyph: c.glyph, bg: c.color, fg: c.fg, size: 84, radius: 24, fontSize: 36),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(c.name, textAlign: TextAlign.center, style: serif(26)),
        const SizedBox(height: 2),
        Text(row.status, textAlign: TextAlign.center, style: sans(13, color: C.muted)),
        if (!mechOn) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(color: C.staleBg, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(child: Text('${sd.name} is off', style: sans(13, color: C.amber))),
              PillButton(
                  label: 'Turn on', height: 36, bg: C.card, fg: C.ink, fontSize: 13, weight: FontWeight.w400, expand: false, padding: 14, onTap: () => vm.enableMechanism(c.mech)),
            ]),
          ),
        ],
        const SizedBox(height: 22),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: chips('Reads', UI.check, C.green, c.reads, C.ink)),
            const SizedBox(width: 10),
            Expanded(child: chips('Never', UI.close, C.red, c.never, C.body)),
          ]),
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GlyphTile(glyph: sd.code, bg: sd.color, fg: C.card, size: 18, radius: 6, fontSize: 11),
          const SizedBox(width: 10),
          Text('New signals wait for your OK', style: sans(12, color: C.muted)),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: PillButton(label: on ? 'Pause' : 'Connect', bg: on ? C.card : C.ink, fg: on ? C.ink : C.paper, onTap: () => vm.toggle(c.id))),
          if (n > 0) ...[
            const SizedBox(width: 8),
            Expanded(child: PillButton(label: 'Forget $n', bg: C.redBg, fg: C.red, fontSize: 14, weight: FontWeight.w400, onTap: () => vm.forgetApp(c.id))),
          ],
        ]),
      ],
    );
  }
}
