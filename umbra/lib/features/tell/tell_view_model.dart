import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../domain/rules.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

class TellState {
  const TellState({this.talk = false, this.layer = 'preference', this.chat = const []});
  /// "Just talk" mode instead of "Remember this".
  final bool talk;

  /// Layer a "Remember this" note is saved to.
  final String layer;
  final List<ChatMsg> chat;

  static const seeds = ['Allergic to peanuts', 'Into Brazilian jazz lately', 'One book at a time', 'On holiday next week'];
  static const chatSeeds = ['Only 15 minutes today', 'Burned out on nonfiction'];

  String get layerNote => switch (layer) {
        'identity' => 'Stable — edits need confirmation',
        'preference' => 'I’ll check in after $staleDays days',
        _ => 'Auto-deletes in $expiryDays days',
      };

  TellState copyWith({bool? talk, String? layer, List<ChatMsg>? chat}) =>
      TellState(talk: talk ?? this.talk, layer: layer ?? this.layer, chat: chat ?? this.chat);
}

/// "Tell me" and "Just talk". Kept alive so the conversation survives closing the sheet.
class TellViewModel extends Notifier<TellState> {
  static final _minsRe = RegExp(r'(\d+)\s*(min|minutes)', caseSensitive: false);
  static final _breakRe = RegExp(r'burn|tired|exhaust|break from', caseSensitive: false);
  static final _ficRe = RegExp(r'fiction|novel', caseSensitive: false);
  static final _learnRe = RegExp(r'learn|studying', caseSensitive: false);
  static final _liveRe = RegExp(r'holiday|week', caseSensitive: false);

  /// Fresh (empty conversation) for every account.
  @override
  TellState build() {
    ref.watch(sessionProvider.select((s) => s.user));
    return const TellState();
  }

  void setTalk(bool talk) => state = state.copyWith(talk: talk);
  void setLayer(String id) => state = state.copyWith(layer: id);
  void pickSeed(String text) => setLayer(_liveRe.hasMatch(text) ? 'live' : 'preference');

  void save(String text) => ref.read(accountProvider.notifier).tell(text, state.layer);

  /// Replies, and if the message sounds worth remembering (and conversation learning is on)
  /// queues it as a signal for review on Today.
  void send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    ({String id, String? memId, String layer, String text})? prop;
    final mm = _minsRe.firstMatch(text);
    if (mm != null) {
      prop = (id: 'c_short', memId: 'l_short', layer: 'live', text: 'Only ~${mm.group(1)} minutes today.');
    } else if (_breakRe.hasMatch(text)) {
      prop = (id: 'c_break', memId: 'l_break', layer: 'live', text: 'A break from heavy nonfiction.');
    } else if (_ficRe.hasMatch(text)) {
      prop = (id: 'c_fic', memId: null, layer: 'preference', text: 'More fiction lately.');
    } else if (_learnRe.hasMatch(text)) {
      prop = (id: 'c_learn', memId: null, layer: 'preference', text: 'Learning: $text');
    }
    final on = ref.read(accountProvider).mech['conversational'] ?? false;
    final reply = !on
        ? 'Got it. Conversation learning is off, so nothing is kept.'
        : prop != null
            ? (mm != null
                ? 'Got it — I shortened tonight’s reading. There’s a card on Today if you want me to remember this.'
                : 'Got it. There’s a card on Today if you want me to remember this.')
            : 'Thanks. Nothing to remember there.';
    final c = [...state.chat, ChatMsg(true, text), ChatMsg(false, reply)];
    state = state.copyWith(chat: c.length > 6 ? c.sublist(c.length - 6) : c);
    if (prop != null && on) {
      ref.read(accountProvider.notifier).propose(Pending(
            id: '${prop.id}${ref.read(clockProvider)().microsecondsSinceEpoch}',
            memId: prop.memId,
            source: 'conversational',
            layer: prop.layer,
            text: prop.text,
            prompt: 'You said: "$text"',
            steps: ['You wrote: "$text"', 'Umbra read it as something worth remembering.'],
          ));
    }
  }
}

final tellViewModelProvider = NotifierProvider<TellViewModel, TellState>(TellViewModel.new);
