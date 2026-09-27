import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import 'tell_view_model.dart';

Future<void> openTellSheet(BuildContext context) => showUmbraSheet(context, (_) => const TellSheet());

class TellSheet extends ConsumerStatefulWidget {
  const TellSheet({super.key});

  @override
  ConsumerState<TellSheet> createState() => _TellSheetState();
}

/// Owns the two text controllers; mode, layer and the conversation live in [TellViewModel].
class _TellSheetState extends ConsumerState<TellSheet> {
  final _tell = TextEditingController();
  final _chat = TextEditingController();

  TellViewModel get _vm => ref.read(tellViewModelProvider.notifier);

  @override
  void dispose() {
    _tell.dispose();
    _chat.dispose();
    super.dispose();
  }

  void _send([String? t]) {
    _vm.send(t ?? _chat.text);
    _chat.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(tellViewModelProvider);
    return SheetFrame(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.sand, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          for (final (talk, label) in const [(false, 'Remember this'), (true, 'Just talk')])
            Expanded(
              child: GestureDetector(
                onTap: () => _vm.setTalk(talk),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  decoration: BoxDecoration(
                    color: s.talk == talk ? C.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: s.talk == talk ? const [BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x1F2B2620))] : const [],
                  ),
                  alignment: Alignment.center,
                  child: Text(label, style: sans(14)),
                ),
              ),
            ),
        ]),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: easeOutSoft,
        alignment: Alignment.topCenter,
        child: s.talk ? _talkView(s) : _rememberView(s),
      ),
    ]);
  }

  Widget _rememberView(TellState s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        UField(controller: _tell, hint: 'Something I should remember…', serifFont: true, fontSize: 19, maxLines: 3, radius: 20, capitalization: TextCapitalization.sentences),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final l in TellState.seeds) ...[
              _SeedChip(
                label: l,
                onTap: () {
                  _tell.text = l;
                  _vm.pickSeed(l);
                },
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          for (final (i, id) in const ['identity', 'preference', 'live'].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _layerPick(id, s.layer)),
          ],
        ]),
        const SizedBox(height: 16),
        Text(
          s.layerNote,
          textAlign: TextAlign.center,
          style: sans(12, color: C.muted),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _tell,
          builder: (_, v, _) => PillButton(
            label: 'Save',
            height: 54,
            enabled: v.text.trim().isNotEmpty,
            onTap: () {
              _vm.save(_tell.text);
              Navigator.pop(context);
            },
          ),
        ),
      ]);

  Widget _layerPick(String id, String current) {
    final L = layerById[id]!;
    final on = current == id;
    return GestureDetector(
      onTap: () => _vm.setLayer(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(color: on ? L.bg : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: on ? L.color : Colors.transparent, width: 2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          LayerShape(id),
          const SizedBox(height: 6),
          Text(L.name, style: sans(13, color: L.color)),
        ]),
      ),
    );
  }

  Widget _talkView(TellState s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (s.chat.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('How’s your day looking?', textAlign: TextAlign.center, style: serif(19, italic: true, color: C.muted)),
              ),
            for (final m in s.chat) _bubble(m),
          ]),
        ),
        if (s.chat.isEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final l in TellState.chatSeeds) ...[_SeedChip(label: l, onTap: () => _send(l)), const SizedBox(width: 8)],
            ]),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(26)),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _chat,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: sans(15),
                decoration: InputDecoration.collapsed(hintText: 'Message', hintStyle: sans(15, color: C.muted)),
              ),
            ),
            RoundIconButton(icon: UI.send, label: 'Send', size: 44, iconSize: 16, bg: C.ink, fg: C.paper, onTap: _send),
          ]),
        ),
        const SizedBox(height: 14),
        Text('I’ll ask before keeping anything.', textAlign: TextAlign.center, style: sans(12, color: C.muted)),
      ]);

  Widget _bubble(ChatMsg m) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .82,
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Align(
              alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: m.mine ? C.ink : C.card, borderRadius: BorderRadius.circular(18)),
                child: Text(m.text, style: sans(14, color: m.mine ? C.paper : C.ink, height: 1.45)),
              ),
            ),
          ),
        ),
      );
}

class _SeedChip extends StatelessWidget {
  const _SeedChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        label: label,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: C.dash)),
          alignment: Alignment.center,
          child: Text(label, style: sans(13, color: C.body)),
        ),
      );
}

