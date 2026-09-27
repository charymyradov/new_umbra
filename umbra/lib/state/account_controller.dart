import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../data/backend.dart';
import '../data/catalog.dart';
import '../data/connect/external_apps.dart';
import '../data/models.dart';
import '../domain/plan.dart';
import '../domain/rules.dart';
import 'providers.dart';
import 'session_controller.dart';
import 'toast_controller.dart';

/// The signed-in account's data and every rule that changes it (the MVVM "model").
///
/// State is an immutable [AccountData]. Changes are saved 250 ms after the last
/// one through the session's [AccountStore], all together as one write;
/// [flush] writes immediately (sign-out, app backgrounded, connecting an app).
class AccountController extends Notifier<AccountData> {
  String? _uid;
  AccountStore? _store;
  Timer? _saveTimer;
  (AccountStore, String, AccountData)? _unsaved;
  Future<bool> _lastWrite = Future.value(true);

  DateTime get _now => ref.read(clockProvider)();
  ToastController get _toast => ref.read(toastProvider.notifier);

  @override
  AccountData build() {
    final session = ref.watch(sessionProvider.select((s) => s.user));
    ref.onDispose(flush);
    _uid = session?.uid;
    // Captured here because refs can't be used inside onDispose.
    final store = _store = session == null ? null : ref.read(sessionProvider.notifier).storeFor(session);
    if (session == null || store == null) return const AccountData(connsOn: defaultConns);
    final loaded = store.peek(session.uid) ?? AccountData(name: session.name, connsOn: defaultConns);
    final rolled = _rollover(loaded, _now);
    if (!identical(rolled, loaded)) _scheduleSave(rolled);
    return rolled;
  }

  // ───────────────────────── persistence ─────────────────────────

  void _scheduleSave(AccountData data) {
    final store = _store, uid = _uid;
    if (store == null || uid == null) return;
    _unsaved = (store, uid, data);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), flush);
  }

  /// Writes pending changes now. Completes with whether they were committed;
  /// a failed write is logged and retried with the next save.
  Future<bool> flush() {
    _saveTimer?.cancel();
    final u = _unsaved;
    if (u == null) return _lastWrite;
    _unsaved = null;
    return _lastWrite = u.$1.save(u.$2, u.$3).then((_) => true, onError: (Object e) {
      debugPrint('Umbra: save failed: $e');
      return false;
    });
  }

  /// Saves what's unsaved, then signs out.
  Future<void> signOut() => ref.read(sessionProvider.notifier).signOut(saved: flush());

  void _commit(AccountData next) {
    state = next;
    _scheduleSave(next);
  }

  AccountData _log(AccountData a, String text) => a.copyWith(log: [LogEntry(_now, text), ...a.log]);

  /// Applies [change], logs it and offers Undo for mem/pending/permission changes.
  void _destroy(String msg, AccountData Function(AccountData) change, [String? logText]) {
    final before = state;
    _commit(_log(change(before), logText ?? msg));
    _toast.show(msg, onUndo: () {
      _commit(_log(
        state.copyWith(mem: before.mem, pending: before.pending, connsOn: before.connsOn, mech: before.mech, sugg: before.sugg),
        'Undid deletion.',
      ));
    });
  }

  // ───────────────────────── day rollover ─────────────────────────

  /// Expires live memories and resets the daily check-in and plan.
  void refreshDay() {
    if (_uid == null || !state.onboarded) return;
    final next = _rollover(state, _now);
    if (!identical(next, state)) _commit(next);
  }

  static AccountData _rollover(AccountData a, DateTime t) {
    if (!a.onboarded) return a;
    var r = a;
    final expired = r.mem.where((m) => m.layer == 'live' && expiresAt(m).isBefore(t)).toList();
    if (expired.isNotEmpty) {
      r = r.copyWith(
        mem: r.mem.where((m) => !expired.contains(m)).toList(),
        log: [for (final m in expired) LogEntry(t, 'Auto-deleted "${m.text}" after $expiryDays days.'), ...r.log],
      );
    }
    if (!r.pulseDoneOn(t) && r.pulse.isNotEmpty) r = r.copyWith(pulse: const {});
    if (r.lastCheckIn != null && daysBetween(r.lastCheckIn!, t) > 1 && r.streak != 0) r = r.copyWith(streak: 0);
    if (r.suggDay == null || daysBetween(r.suggDay!, t) != 0) r = r.copyWith(sugg: const {}, suggDay: dayOf(t));
    return r;
  }

  // ───────────────────────── onboarding ─────────────────────────

  void setName(String v) => _commit(state.copyWith(name: v));
  void setRole(String v) => _commit(state.copyWith(role: v));

  void toggleDomain(String id) {
    final d = state.chosenDomains;
    _commit(state.copyWith(chosenDomains: d.contains(id) ? (d.toList()..remove(id)) : [...d, id]));
  }

  void obBack() {
    if (state.ob > 1) _commit(state.copyWith(ob: state.ob - 1));
  }

  /// Moves to the next onboarding step; returns true when onboarding finished.
  bool obNext() {
    if (state.ob < 3) {
      _commit(state.copyWith(ob: state.ob + 1));
      return false;
    }
    final t = _now;
    const steps = ['You chose this during onboarding.', 'Saved directly — you said it.'];
    final nm = state.name.trim();
    final role = state.role.trim();
    Memory fact(String id, String text) => Memory(id: id, layer: 'identity', text: text, source: 'explicit', detail: 'Onboarding', steps: steps, created: t, confirmed: t);
    _commit(state.copyWith(
      onboarded: true,
      name: nm.isEmpty ? 'there' : nm,
      mem: [
        if (nm.isNotEmpty) fact('i_name', 'Your name is $nm.'),
        if (role.isNotEmpty) fact('i_role', 'You work as ${RegExp(r'^[aeiou]', caseSensitive: false).hasMatch(role) ? 'an' : 'a'} ${role.toLowerCase()}.'),
      ],
      pending: const [],
      log: [LogEntry(t, 'Saved what you told me during setup.')],
      suggDay: dayOf(t),
    ));
    return true;
  }

  // ───────────────────────── memory ─────────────────────────

  void forget(String id) {
    final m = state.memById(id);
    if (m == null) return;
    _destroy('Forgot "${clip(m.text, 30)}"', (a) => a.copyWith(mem: a.mem.where((x) => x.id != id).toList()), 'Deleted "${m.text}"');
  }

  void reconfirm(String id) {
    final m = state.memById(id);
    if (m == null) return;
    final t = _now;
    _commit(_log(
      state.copyWith(mem: [for (final x in state.mem) x.id == id ? x.copyWith(confirmed: t, steps: [...x.steps, 'Re-confirmed on ${fmtDate(t)}.']) : x]),
      'Re-confirmed "${m.text}"',
    ));
    _toast.show('Marked still true');
  }

  void edit(String id, String text) {
    final m = state.memById(id);
    final t = text.trim();
    if (m == null || t.isEmpty || t == m.text) return;
    final now = _now;
    _commit(_log(
      state.copyWith(mem: [
        for (final x in state.mem)
          x.id == id ? x.copyWith(text: t, confirmed: x.confirmed != null ? now : null, steps: [...x.steps, 'You edited this (was "${x.text}").']) : x
      ]),
      'Edited "${m.text}" → "$t"',
    ));
    _toast.show('Updated');
  }

  /// Adds something the person typed in Memory, optionally tagged with a domain.
  void add(String layer, String text, {String? domain}) {
    final t = text.trim();
    if (t.isEmpty) return;
    final L = layerById[layer]!;
    final now = _now;
    _commit(_log(
      state.copyWith(mem: [
        ...state.mem,
        Memory(
            id: 'u${now.microsecondsSinceEpoch}',
            layer: layer,
            text: t,
            source: 'explicit',
            domain: domain,
            sensitive: domain == 'health',
            detail: 'Added in Memory, ${fmtDate(now)}',
            steps: ['You added this in Memory: "$t"', 'Saved directly — you said it.'],
            created: now,
            confirmed: now),
      ]),
      'Added to ${L.name}: "$t"',
    ));
    _toast.show('Added to ${L.name}');
  }

  static final _healthRe = RegExp(r'allerg|sleep|run|diet|vegan|vegetarian|gym|pain|asthma|walk|yoga', caseSensitive: false);
  static final _musicRe = RegExp(r'jazz|music|song|album|band|playlist|artist', caseSensitive: false);
  static final _readRe = RegExp(r'book|read|novel|author', caseSensitive: false);

  /// "Tell me" — saves directly and guesses the domain from the words used.
  void tell(String text, String layer) {
    final t = text.trim();
    if (t.isEmpty) return;
    final gd = _healthRe.hasMatch(t)
        ? 'health'
        : _musicRe.hasMatch(t)
            ? 'music'
            : _readRe.hasMatch(t)
                ? 'reading'
                : 'core';
    final now = _now;
    _commit(_log(
      state.copyWith(mem: [
        ...state.mem,
        Memory(
            id: 't${now.microsecondsSinceEpoch}',
            domain: gd,
            sensitive: gd == 'health',
            layer: layer,
            text: t,
            source: 'explicit',
            detail: 'Tell me, ${fmtDate(now)}',
            steps: ['You wrote: "$t"', 'Saved directly — you said it.'],
            created: now,
            confirmed: now),
      ]),
      'You told me "$t"',
    ));
    _toast.show('Saved to ${layerById[layer]!.name}');
  }

  // ───────────────────────── pending signals ─────────────────────────

  void keep(Pending p, [String? editedText]) {
    final text = editedText ?? p.text;
    final t = _now;
    final m = Memory(
      id: p.memId ?? 'm_${p.id}',
      domain: p.domain,
      sensitive: p.sensitive,
      layer: p.layer,
      text: text,
      source: p.source,
      conn: p.conn,
      detail: p.prompt,
      steps: [...p.steps, if (editedText != null) 'You edited it to "$text".', 'You tapped Keep on ${fmtDate(t)}.'],
      created: t,
      confirmed: t,
      confidence: p.conf,
      basis: p.basis,
    );
    _commit(_log(
      state.copyWith(mem: [...state.mem.where((x) => x.id != m.id), m], pending: state.pending.where((x) => x.id != p.id).toList()),
      'Kept "$text"',
    ));
    _toast.show('Saved to ${layerById[p.layer]!.name}');
  }

  void reject(Pending p) {
    _commit(_log(state.copyWith(pending: state.pending.where((x) => x.id != p.id).toList()), 'Rejected "${p.text}" — not stored.'));
    _toast.show('Not stored');
  }

  /// Queues a new signal first; one with the same [Pending.memId] replaces the older one.
  void propose(Pending p) {
    _commit(state.copyWith(pending: [p, ...state.pending.where((x) => p.memId == null || x.memId != p.memId)]));
  }

  // ───────────────────────── bulk forget ─────────────────────────

  void forgetBySource(String k) {
    final n = state.count((m) => m.source == k);
    if (n == 0) return;
    _destroy('Forgot $n from ${src[k]!.name.toLowerCase()}', (a) => a.copyWith(mem: a.mem.where((m) => m.source != k).toList()));
  }

  void forgetLayer(String id) {
    if (state.count((m) => m.layer == id) == 0) return;
    _destroy('Forgot all ${layerById[id]!.name.toLowerCase()}', (a) => a.copyWith(mem: a.mem.where((m) => m.layer != id).toList()));
  }

  void forgetAll() {
    if (state.mem.isEmpty && state.pending.isEmpty) return;
    _destroy('Everything forgotten', (a) => a.copyWith(mem: const [], pending: const []), 'Deleted everything.');
  }

  // ───────────────────────── permissions & apps ─────────────────────────

  void toggleMech(String k) {
    if (k == 'explicit') return;
    final on = state.mech[k] ?? false;
    var next = state.copyWith(mech: {...state.mech, k: !on});
    if (state.onboarded) {
      next = _log(next, '${src[k]!.name} turned ${on ? 'off' : 'on'}.');
      _toast.show('${src[k]!.name} ${on ? 'off' : 'on'}');
    }
    _commit(next);
  }

  void enableMech(String k) {
    _commit(_log(state.copyWith(mech: {...state.mech, k: true}), '${src[k]!.name} turned on.'));
    _toast.show('${src[k]!.name} on');
  }

  void toggleConn(String id) {
    final c = connById[id]!;
    final on = state.connsOn[id] ?? false;
    _commit(_log(state.copyWith(connsOn: {...state.connsOn, id: !on}), '${c.name} ${on ? 'paused' : 'connected'}.'));
    _toast.show('${c.name} ${on ? 'paused' : 'connected'}');
  }

  void removeConn(String id) {
    final c = connById[id]!;
    final n = state.count((m) => m.conn == id);
    _destroy(
      'Disconnected ${c.name}, forgot $n',
      (a) => a.copyWith(
        connsOn: {...a.connsOn, id: false},
        mem: a.mem.where((m) => m.conn != id).toList(),
        pending: a.pending.where((p) => p.conn != id).toList(),
      ),
    );
  }

  void toggleHealthExport() {
    final on = !state.healthExport;
    _commit(state.copyWith(healthExport: on));
    _toast.show(on ? 'Health included in exports' : 'Health left out of exports');
  }

  void logExport(String what) => _commit(_log(state, 'Exported $what.'));

  // ───────────────────────── apps signed in with Umbra ─────────────────────────

  /// Records that [app] may read [scopes]. Its share document, its grant and the
  /// log entry are written together by the next save.
  void linkApp(ExternalAppDef app, List<String> scopes) {
    final again = state.linked.containsKey(app.id);
    _commit(_log(
      state.copyWith(linked: {...state.linked, app.id: LinkedApp(scopes: scopes, since: _now)}),
      again ? '${app.name} signed in again with your Umbra account.' : '${app.name} connected with your Umbra account.',
    ));
  }

  /// Stops sharing with [appId]: its share document is deleted, so it loses access at once.
  void unlinkApp(String appId) {
    if (!state.linked.containsKey(appId)) return;
    final name = kExternalApps[appId]?.name ?? appId;
    _commit(_log(state.copyWith(linked: {...state.linked}..remove(appId)), '$name disconnected.'));
    _toast.show('$name disconnected');
  }

  // ───────────────────────── memory layers (persisted disclosure) ─────────────────────────

  void setLayerOpen(String id, bool open) => _commit(state.copyWith(openL: {...state.openL, id: open}));

  void openAllLayers() => _commit(state.copyWith(openL: {for (final l in layers) l.id: true}));

  // ───────────────────────── today ─────────────────────────

  void startSuggestion(PlanItem p) {
    final t = _now;
    var next = _log(state.copyWith(sugg: {...state.sugg, p.s.id: 'done'}), 'Started ${p.s.title}.');
    if ((state.mech['behavioral'] ?? false) && !state.morningAsked && p.s.isReading && t.hour < 12) {
      next = next.copyWith(morningAsked: true, pending: [
        Pending(
            id: 'q_morning',
            source: 'behavioral',
            prompt: 'You started reading at ${fmtTime(t)} — usually it’s evenings.',
            layer: 'pattern',
            text: 'Mornings might work too.',
            conf: 0.2,
            basis: '1 session',
            steps: ['You tapped Start on "${p.s.title}" at ${fmtTime(t)}.']),
        ...next.pending,
      ]);
      _toast.show('Enjoy. I noticed something — see "Is this you?".');
    } else {
      _toast.show(p.s.isReading ? 'Enjoy your reading' : 'Enjoy');
    }
    _commit(next);
  }

  void skipSuggestion(PlanItem p) {
    _commit(_log(state.copyWith(sugg: {...state.sugg, p.s.id: 'hidden'}), '"Not now" on ${p.s.title}.'));
    _toast.show('Removed from today');
  }

  /// Records one check-in answer; the third answer completes the check-in.
  void setPulse(String k, String v) {
    final t = _now;
    if (state.pulseDoneOn(t)) return;
    final p = {...state.pulse, k: v};
    if (!(p.containsKey('sleep') && p.containsKey('energy') && p.containsKey('sound'))) {
      _commit(state.copyWith(pulse: p));
      return;
    }
    Memory live(String id, String domain, String text, bool sensitive) => Memory(
        id: id,
        domain: domain,
        sensitive: sensitive,
        layer: 'live',
        text: text,
        source: 'explicit',
        detail: 'Morning check-in, ${fmtDate(t)}',
        steps: const ['You tapped it in this morning’s check-in.', 'Saved directly — you said it.'],
        created: t,
        confirmed: t);
    final sleep = p['sleep']!, energy = p['energy']!, sound = p['sound']!;
    final ms = [
      live('l_p_sleep', 'health', 'Slept ${sleep == 'Rough' ? 'badly' : sleep == 'Okay' ? 'okay' : 'well'} last night.', true),
      live('l_p_energy', 'health', 'Energy $energy/5 this morning.', true),
      live('l_p_sound', 'music', sound == 'Quiet' ? 'Wants quiet today.' : 'In the mood for ${sound.toLowerCase()} today.', false),
    ];
    final checkIns = state.streak + 1;
    final insight = (state.mech['behavioral'] ?? false) && checkIns >= 3 && !state.has('pt_cross')
        ? Pending(
            id: 'q_cross${t.microsecondsSinceEpoch}',
            memId: 'pt_cross',
            domain: 'music',
            source: 'behavioral',
            prompt: 'Across $checkIns check-ins, your sleep and soundtrack picks move together.',
            layer: 'pattern',
            text: sleep == 'Rough' ? 'After rough nights you reach for calm music.' : 'Well-rested days bring more upbeat picks.',
            conf: 0.5,
            basis: '$checkIns check-ins',
            steps: ['$checkIns morning check-ins compared.', 'Sleep answers lined up with soundtrack picks on most of them.'])
        : null;
    final yesterday = state.lastCheckIn != null && daysBetween(state.lastCheckIn!, t) == 1;
    _commit(_log(
      state.copyWith(
        pulse: p,
        streak: yesterday ? state.streak + 1 : 1,
        lastCheckIn: t,
        xp: state.xp + 20,
        mem: [...state.mem.where((m) => !m.id.startsWith('l_p_')), ...ms],
        pending: insight == null ? null : [insight, ...state.pending.where((x) => x.memId != 'pt_cross')],
      ),
      'Checked in: sleep ${sleep.toLowerCase()}, energy $energy/5, ${sound.toLowerCase()}.',
    ));
    _toast.show('Checked in · +20 XP${insight != null ? ' · a pattern to review' : ''}');
  }

  // ───────────────────────── quizzes ─────────────────────────

  void commitQuest(String dom, List<QuizItem> items, int gained) {
    final q = quests[dom]!;
    final t = _now;
    final ms = [
      for (final it in items)
        Memory(
            id: it.id,
            layer: it.layer,
            text: it.text,
            domain: it.domain,
            sensitive: it.sensitive,
            source: 'explicit',
            detail: '${q.title} quiz, ${fmtDate(t)}',
            steps: ['You answered "${it.q}" with "${it.a}".', 'Saved directly — you said it.'],
            created: t,
            confirmed: t),
    ];
    List<String>? answer(String id) => items.where((it) => it.id == id).map((it) => it.a.split(', ')).firstOrNull;
    // The reading quiz also fills the structured profile connected apps read.
    final medium = answer('q_reading_medium')?.first;
    final audio = items.any((it) => it.id == 'q_reading_habits_3');
    final formats = dom != 'reading' || (medium == null && !audio)
        ? null
        : [if (medium == 'Paper') 'print', if (medium == 'Screen') 'ebook', if (audio) 'audio'];
    _commit(_log(
      state.copyWith(
        // A replay replaces earlier answers; a quiz where everything was skipped keeps them.
        mem: ms.isEmpty ? null : [...state.mem.where((m) => !m.id.startsWith('q_${dom}_')), ...ms],
        topics: answer('q_reading_topics'),
        times: answer('q_reading_when'),
        formats: formats,
        xp: state.xp + gained,
        questsDone: {...state.questsDone, dom},
        chosenDomains: state.chosenDomains.contains(dom) ? null : [...state.chosenDomains, dom],
      ),
      'Played the ${domainById[dom]!.name} quiz, saved ${ms.length}.',
    ));
    _toast.show('Saved ${ms.length} to ${domainById[dom]!.name} · +$gained XP');
  }
}

final accountProvider = NotifierProvider<AccountController, AccountData>(AccountController.new);
