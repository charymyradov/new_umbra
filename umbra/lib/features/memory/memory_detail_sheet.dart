import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/rules.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import 'memory_detail_view_model.dart';

Future<void> openMemorySheet(BuildContext context, String id) => showUmbraSheet(context, (_) => MemoryDetailSheet(id: id));

/// "How I know this" for one memory: provenance, facts, edit (with identity review), forget.
class MemoryDetailSheet extends ConsumerStatefulWidget {
  const MemoryDetailSheet({super.key, required this.id});
  final String id;

  @override
  ConsumerState<MemoryDetailSheet> createState() => _MemoryDetailSheetState();
}

class _MemoryDetailSheetState extends ConsumerState<MemoryDetailSheet> {
  final _text = TextEditingController();
  bool _closing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(memoryDetailViewModelProvider(widget.id));
    final vm = ref.read(memoryDetailViewModelProvider(widget.id).notifier);
    final m = st.memory;
    if (m == null) {
      // Forgotten (here or elsewhere): close on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      return const SizedBox.shrink();
    }
    final L = st.layer;
    final sd = st.source;
    final editing = st.stage == EditStage.edit, reviewing = st.stage == EditStage.review;

    return SheetFrame(gap: 20, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: L.bg, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            LayerShape(m.layer),
            const SizedBox(width: 8),
            Expanded(child: Text('${L.name} · ${L.tag}'.toUpperCase(), style: caps(11, color: L.color))),
            if (m.sensitive) ...[const UIcon(UI.lock, size: 12, color: C.teal), const SizedBox(width: 10)],
            RoundIconButton(icon: UI.close, label: 'Close', onTap: _close),
          ]),
          const SizedBox(height: 16),
          if (editing)
            UField(controller: _text, serifFont: true, fontSize: 18, maxLines: 3, radius: 14, autofocus: true)
          else
            Text(m.text, style: serif(26, height: 1.2)),
          if (m.layer == 'pattern' && m.confidence != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              ConfDots(m.confidence),
              const SizedBox(width: 10),
              Expanded(child: Text('${confWord(m.confidence!)} · ${m.basis ?? ''}', style: sans(13, color: C.blue))),
            ]),
          ],
          if (m.layer == 'live') ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: st.daysLeftCount / expiryDays, minHeight: 5, color: C.green, backgroundColor: const Color(0xFFD5E0CB)),
                ),
              ),
              const SizedBox(width: 10),
              Text('${st.daysLeftCount}d left · ${fmtDate(st.expires)}', style: sans(13, color: C.green)),
            ]),
          ],
          if (m.layer == 'preference' && m.confirmed != null) ...[
            const SizedBox(height: 16),
            Text('Last confirmed ${fmtDate(m.confirmed!)}', style: sans(13, color: C.amber)),
          ],
        ]),
      ),
      if (editing)
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (st.isIdentity)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
              child: Text('Identity changes are reviewed before saving.', style: sans(13, color: C.body)),
            ),
          Row(children: [
            Expanded(
              child: PillButton(
                label: st.isIdentity ? 'Review change' : 'Save',
                height: 50,
                fontSize: 14,
                weight: FontWeight.w400,
                onTap: () => vm.submit(_text.text),
              ),
            ),
            TextLink('Cancel', height: 50, onTap: vm.cancel),
            const SizedBox(width: 12),
          ]),
        ]),
      if (reviewing)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Confirm identity change', style: sans(14, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _diff('Before', m.text, C.redBg, C.red)),
                const SizedBox(width: 8),
                Expanded(child: _diff('After', st.draft, C.greenOk, C.green)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: PillButton(
                  label: 'Confirm',
                  height: 48,
                  fontSize: 14,
                  weight: FontWeight.w400,
                  onTap: vm.confirmReview,
                ),
              ),
              TextLink('Keep original', height: 48, onTap: vm.cancel),
              const SizedBox(width: 12),
            ]),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('How I know this', style: serif(20)),
          const SizedBox(height: 14),
          Row(children: [
            GlyphTile(glyph: sd.code, bg: sd.color, fg: C.card, size: 40, radius: 13, fontSize: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(st.sourceLine, style: sans(14, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(st.certainty, style: sans(12, color: C.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          for (final (i, step) in m.steps.indexed)
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                  width: 40,
                  child: Column(children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: i == m.steps.length - 1 ? C.ink : const Color(0xFFCFC5B4), shape: BoxShape.circle),
                    ),
                    Expanded(child: Container(width: 1.5, color: i == m.steps.length - 1 ? Colors.transparent : C.line)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(step, style: sans(14, height: 1.45)))),
              ]),
            ),
        ]),
      ),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (k, v) in st.facts)
          LayoutBuilder(
            builder: (context, cons) => SizedBox(
              width: (cons.maxWidth - 8) / 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(k, style: sans(11, color: C.muted)),
                  const SizedBox(height: 4),
                  Text(v, style: sans(14)),
                ]),
              ),
            ),
          ),
      ]),
      if (st.uses.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(children: [
            const UIcon(UI.book, size: 16, color: C.body),
            const SizedBox(width: 10),
            Expanded(child: Text('Shaping: ${st.uses.join(', ')}', style: sans(13, color: C.body))),
          ]),
        ),
      if (st.stage == EditStage.none)
        Row(children: [
          Expanded(child: PillButton(label: 'Forget', bg: C.red, fg: C.card, fontSize: 14, onTap: vm.forget)),
          if (m.layer == 'preference') ...[
            const SizedBox(width: 8),
            Expanded(child: PillButton(label: 'Still true', bg: C.card, fg: C.ink, fontSize: 14, weight: FontWeight.w400, onTap: vm.reconfirm)),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: PillButton(
              label: 'Edit',
              bg: C.card,
              fg: C.ink,
              fontSize: 14,
              weight: FontWeight.w400,
              onTap: () {
                _text.text = m.text;
                vm.startEdit();
              },
            ),
          ),
        ]),
    ]);
  }

  Widget _diff(String label, String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: sans(11, color: fg)),
          const SizedBox(height: 4),
          Text(text, style: sans(14, height: 1.35)),
        ]),
      );
}

