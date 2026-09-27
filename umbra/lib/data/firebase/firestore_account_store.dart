import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../domain/rules.dart';
import '../backend.dart';
import '../catalog.dart';
import '../connect/external_apps.dart';
import '../models.dart';

/// Keeps an account in Firestore, in the layout LitList and the auth worker
/// also use (see `firestore.rules`):
///
///   users/{uid}                  profile (full_name, role, reading) + `umbra` app state
///   users/{uid}/shared/{appId}   the one document a connected app may read
///   memories/{uid}_{memId}       one memory per document
///   events/{id}                  log entries, "Is this you?" proposals and their resolution
///   app_grants/{uid}_{appId}     a data source (Kindle, Podcasts…) or a connected app (LitList)
///
/// [save] compares the account with what Firestore last had and sends the whole
/// difference as a single [WriteBatch]: a change lands completely or not at all,
/// never half-written. (Only a change touching more than [_maxOps] documents,
/// e.g. forgetting hundreds of memories, is split into several batches.)
class FirestoreAccountStore implements AccountStore {
  FirestoreAccountStore(this._db, {this.clock = DateTime.now});

  final FirebaseFirestore _db;
  final DateTime Function() clock;
  final _remote = <String, _Remote>{};
  final _resyncs = <String, Future<void>>{};

  static const _maxOps = 450;

  @override
  AccountData? peek(String uid) => _remote[uid]?.data;

  // ───────────────────────── load ─────────────────────────

  @override
  Future<AccountData?> load(String uid) async {
    final (user, mems, events, grants) = await (
      _db.doc(_userPath(uid)).get(),
      _db.collection('memories').where('user_id', isEqualTo: uid).get(),
      _db.collection('events').where('user_id', isEqualTo: uid).get(),
      _db.collection('app_grants').where('user_id', isEqualTo: uid).get(),
    ).wait;

    final r = _Remote()..userExists = user.exists;
    _remote[uid] = r;

    // Data sources and connected apps.
    final connsOn = {...defaultConns};
    final linked = <String, LinkedApp>{};
    for (final d in grants.docs) {
      final g = d.data();
      final appId = g['app_id'] as String? ?? '';
      final active = g['duration'] != 'revoked' && g['revoked_at'] == null;
      final path = 'app_grants/${d.id}';
      if (g['kind'] == 'external_app') {
        r.docs[path] = _pick(g, _externalGrantKeys);
        if (active) linked[appId] = LinkedApp(scopes: _strs(g['scopes']), since: _date(g['granted_at']) ?? clock());
      } else {
        r.docs[path] = _pick(g, _connGrantKeys);
        if (connById.containsKey(appId)) connsOn[appId] = active;
      }
    }

    // Memories, oldest first like everywhere else in the app.
    final mem = <Memory>[];
    for (final d in mems.docs) {
      final m = _memoryFrom(d.id, d.data());
      r.memDoc[m.id] = d.id;
      mem.add(m);
    }
    mem.sort((a, b) => a.created.compareTo(b.created));

    // Log, open proposals and (for accounts made by the first Firebase version) settings.
    final log = <LogEntry>[];
    final proposals = <String, Map<String, Object?>>{};
    final resolved = <String>{};
    Map<String, Object?>? legacySettings;
    DateTime? legacyAt;
    for (final d in events.docs) {
      final e = d.data();
      final payload = Map<String, Object?>.from(e['payload'] as Map? ?? const {});
      final at = _date(e['created_at']) ?? clock();
      switch (e['kind']) {
        case 'log':
          final entry = LogEntry(at, payload['text'] as String? ?? '');
          log.add(entry);
          r.logKeys.add(_logKey(entry));
        case 'proposal':
          proposals[d.id] = payload;
        case 'proposal_resolved':
          resolved.add('${payload['proposal_id']}');
        case 'settings':
          if (legacyAt == null || at.isAfter(legacyAt)) (legacySettings, legacyAt) = (payload, at);
      }
    }
    log.sort((a, b) => b.at.compareTo(a.at));
    final pending = <Pending>[];
    for (final MapEntry(key: docId, value: p) in proposals.entries) {
      if (resolved.contains(docId)) continue;
      final pend = _pendingFrom(docId, p);
      r.pendingDoc[pend.id] = docId;
      pending.add(pend);
    }

    if (!user.exists && mem.isEmpty && grants.docs.isEmpty) return null;

    final u = user.data() ?? const <String, Object?>{};
    final reading = Map<String, Object?>.from(u['reading'] as Map? ?? const {});
    final a = _accountFrom(
      Map<String, Object?>.from(u['umbra'] as Map? ?? const {}),
      legacy: u['umbra'] == null ? (legacySettings ?? const {}) : null,
    ).copyWith(
      name: u['full_name'] as String? ?? '',
      role: u['role'] as String? ?? '',
      topics: _strs(reading['topics']),
      times: _strs(reading['times']),
      formats: _strs(reading['formats']),
      connsOn: connsOn,
      linked: linked,
      mem: mem,
      pending: pending,
      log: log.take(200).toList(),
    );
    final loaded = a.onboarded || u['umbra'] != null ? a : a.copyWith(onboarded: mem.isNotEmpty);
    r.data = loaded;

    // What Firestore has, in the same shape [_desired] produces, so an unchanged
    // account writes nothing. A profile from the first Firebase version has no
    // `umbra` map yet; leaving it out makes the first save add it.
    if (u['umbra'] != null) r.docs[_userPath(uid)] = _userDoc(loaded);
    for (final m in mem) {
      r.docs['memories/${r.memDoc[m.id]}'] = _memoryDoc(uid, m);
    }
    for (final p in pending) {
      r.docs['events/${r.pendingDoc[p.id]}'] = _proposalDoc(uid, p);
    }
    for (final appId in linked.keys) {
      final s = await _db.doc(_sharePath(uid, appId)).get();
      if (s.exists) r.docs[_sharePath(uid, appId)] = {...?s.data()}..remove('updated_at');
    }
    return loaded;
  }

  // ───────────────────────── save ─────────────────────────

  @override
  Future<void> save(String uid, AccountData data) {
    final resync = _resyncs[uid];
    if (resync != null) return resync.then((_) => save(uid, data));
    final r = _remote[uid] ?? (_remote[uid] = _Remote());
    if (r.stale) {
      final f = _resyncs[uid] = load(uid).then((_) {}, onError: (Object e) => debugPrint('Umbra: resync failed: $e')).whenComplete(() => _resyncs.remove(uid));
      return f.then((_) => save(uid, data));
    }

    final now = clock();
    final ops = _diff(uid, r, data, now);
    r.data = data;
    if (ops.isEmpty) return Future.value();

    // Firestore applies each batch to its local cache immediately, so what it
    // "has" is updated right away; a rejected batch marks the account for a
    // re-read before the next save.
    final commits = <Future<void>>[];
    for (var i = 0; i < ops.length; i += _maxOps) {
      final batch = _db.batch();
      for (final op in ops.skip(i).take(_maxOps)) {
        op.apply(_db, batch);
        op.record(r);
      }
      commits.add(batch.commit());
    }
    return Future.wait(commits).then((_) {}, onError: (Object e) {
      r.stale = true;
      debugPrint('Umbra: save failed, will re-read before the next one: $e');
      throw e;
    });
  }

  List<_Op> _diff(String uid, _Remote r, AccountData a, DateTime now) {
    final want = _desired(uid, a, r, now);
    final ops = <_Op>[];

    for (final MapEntry(key: path, value: doc) in want.entries) {
      final had = r.docs[path];
      if (had != null && _deepEq(had, doc)) continue;
      ops.add(_Op.set(path, doc, _stamped(uid, path, doc, isNew: had == null, now: now, r: r)));
    }
    for (final path in r.docs.keys) {
      if (!want.containsKey(path) && _deletable(uid, path)) ops.add(_Op.delete(path));
    }
    // The log is append-only: only entries Firestore hasn't seen are added.
    for (final l in a.log.reversed) {
      final key = _logKey(l);
      if (r.logKeys.contains(key)) continue;
      ops.add(_Op.log(key, 'events/${uid}_l_${l.at.toUtc().microsecondsSinceEpoch}_${_short(l.text)}', {
        'user_id': uid,
        'app_id': 'umbra',
        'kind': 'log',
        'payload': {'text': l.text},
        'created_at': _iso(l.at),
      }));
    }
    return ops;
  }

  /// Every document the account should have, keyed by path.
  Map<String, Map<String, Object?>> _desired(String uid, AccountData a, _Remote r, DateTime now) {
    final want = <String, Map<String, Object?>>{_userPath(uid): _userDoc(a)};

    final memDocIds = <String, String>{};
    for (final m in a.mem) {
      final id = r.memDoc[m.id] ?? '${uid}_${m.id}';
      memDocIds[m.id] = id;
      want['memories/$id'] = _memoryDoc(uid, m);
    }

    for (final c in conns) {
      final path = 'app_grants/${uid}_${c.id}';
      final on = a.connsOn[c.id] ?? false;
      final had = r.docs[path];
      if (!on && had == null) continue;
      final wasOn = had != null && had['duration'] != 'revoked';
      want[path] = {
        'user_id': uid,
        'app_id': c.id,
        'app_name': c.name,
        'duration': on ? '30d' : 'revoked',
        'granted_at': on && !wasOn ? _iso(now) : had?['granted_at'] ?? _iso(now),
        'revoked_at': on ? null : (wasOn ? _iso(now) : had?['revoked_at'] ?? _iso(now)),
        'allowed_memory_ids': on ? [for (final m in a.mem) if (m.conn == c.id) memDocIds[m.id]] : const <String>[],
      };
    }

    final appIds = {...kExternalApps.keys, ...a.linked.keys};
    for (final appId in appIds) {
      final path = 'app_grants/${uid}_$appId';
      final link = a.linked[appId];
      final had = r.docs[path];
      if (link != null) {
        want[path] = {
          'user_id': uid,
          'app_id': appId,
          'app_name': kExternalApps[appId]?.name ?? appId,
          'kind': 'external_app',
          'duration': 'linked',
          'scopes': link.scopes,
          'granted_at': _iso(link.since),
          'revoked_at': null,
        };
        want[_sharePath(uid, appId)] = buildShare(a, appId, link.scopes, now);
      } else if (had != null) {
        want[path] = {...had, 'duration': 'revoked', 'revoked_at': had['duration'] == 'revoked' ? had['revoked_at'] : _iso(now)};
      }
    }

    // Open proposals; ones answered since the last save get a resolution marker
    // (the proposal itself stays, like the append-only history it is).
    final open = {for (final p in a.pending) r.pendingDoc[p.id] ?? '${uid}_p_${p.id}': p};
    for (final MapEntry(key: docId, value: p) in open.entries) {
      want['events/$docId'] = _proposalDoc(uid, p);
    }
    for (final path in r.docs.keys) {
      if (!path.startsWith('events/') || path.endsWith('_r')) continue;
      final docId = path.substring('events/'.length);
      if (open.containsKey(docId)) continue;
      want[path] = r.docs[path]!;
      final marker = '${path}_r';
      want[marker] = r.docs[marker] ??
          {
            'user_id': uid,
            'app_id': 'umbra',
            'kind': 'proposal_resolved',
            'payload': {'proposal_id': docId, 'action': _answered(r, docId, a) ? 'keep' : 'reject'},
          };
    }
    return want;
  }

  /// The document as written: [doc] plus timestamps that aren't compared.
  Map<String, Object?> _stamped(String uid, String path, Map<String, Object?> doc, {required bool isNew, required DateTime now, required _Remote r}) {
    if (path == _userPath(uid)) {
      return {...doc, 'updated_at': _iso(now), if (!r.userExists) 'created_at': _iso(now)};
    }
    if (path.startsWith('users/')) return {...doc, 'updated_at': _iso(now)};
    if (path.startsWith('events/') && isNew) return {...doc, 'created_at': _iso(now)};
    return doc;
  }

  bool _deletable(String uid, String path) =>
      path.startsWith('memories/') || path.startsWith('users/$uid/shared/') || (path.startsWith('events/') && path.endsWith('_r'));

  /// Whether the pending item behind proposal [docId] ended up in memory.
  bool _answered(_Remote r, String docId, AccountData a) {
    final id = r.pendingDoc.entries.where((e) => e.value == docId).map((e) => e.key).firstOrNull;
    final p = r.data.pending.where((x) => x.id == id).firstOrNull;
    return p != null && a.has(p.memId ?? 'm_${p.id}');
  }

  // ───────────────────────── mapping ─────────────────────────

  static String _userPath(String uid) => 'users/$uid';
  static String _sharePath(String uid, String appId) => 'users/$uid/shared/$appId';

  static Map<String, Object?> _userDoc(AccountData a) => {
        'full_name': a.name,
        'role': a.role,
        'reading': {'topics': a.topics, 'times': a.times, 'formats': a.formats},
        'umbra': {
          'onboarded': a.onboarded,
          'ob': a.ob,
          'domains': a.chosenDomains,
          'mech': a.mech,
          'sugg': a.sugg,
          'sugg_day': _isoOrNull(a.suggDay),
          'morning_asked': a.morningAsked,
          'quests': (a.questsDone.toList()..sort()),
          'xp': a.xp,
          'streak': a.streak,
          'pulse': a.pulse,
          'last_check_in': _isoOrNull(a.lastCheckIn),
          'health_export': a.healthExport,
          'open_layers': a.openL,
        },
      };

  static AccountData _accountFrom(Map<String, Object?> u, {Map<String, Object?>? legacy}) {
    Map<String, bool> bools(Object? v) => {...?(v as Map?)?.map((k, v) => MapEntry('$k', v == true))};
    Map<String, String> strMap(Object? v) => {...?(v as Map?)?.map((k, v) => MapEntry('$k', '$v'))};
    if (legacy != null) {
      return AccountData(onboarded: legacy['onboarded'] == true, mech: {...AccountData.defaultMech, ...bools(legacy['mech']), 'explicit': true});
    }
    return AccountData(
      onboarded: u['onboarded'] == true,
      ob: (u['ob'] as num?)?.toInt() ?? 1,
      chosenDomains: u['domains'] == null ? const ['reading', 'music', 'health'] : _strs(u['domains']),
      mech: {...AccountData.defaultMech, ...bools(u['mech']), 'explicit': true},
      sugg: strMap(u['sugg']),
      suggDay: _date(u['sugg_day']),
      morningAsked: u['morning_asked'] == true,
      questsDone: _strs(u['quests']).toSet(),
      xp: (u['xp'] as num?)?.toInt() ?? 0,
      streak: (u['streak'] as num?)?.toInt() ?? 0,
      pulse: strMap(u['pulse']),
      lastCheckIn: _date(u['last_check_in']),
      healthExport: u['health_export'] == true,
      openL: bools(u['open_layers']),
    );
  }

  static Map<String, Object?> _memoryDoc(String uid, Memory m) => {
        'user_id': uid,
        'mem_id': m.id,
        'layer': m.layer,
        'statement': m.text,
        'source': m.source,
        'connection': m.conn,
        'domain': m.domain,
        'sensitive': m.sensitive,
        'detail': m.detail,
        'derivation': m.steps,
        'confidence': m.confidence,
        'basis': m.basis,
        'created_at': _iso(m.created),
        'confirmed_at': _isoOrNull(m.confirmed),
        'expires_at': m.layer == 'live' ? _iso(expiresAt(m)) : null,
      };

  static Memory _memoryFrom(String docId, Map<String, Object?> d) => Memory(
        id: d['mem_id'] as String? ?? docId,
        layer: d['layer'] as String? ?? 'preference',
        text: d['statement'] as String? ?? '',
        source: d['source'] as String? ?? 'explicit',
        conn: d['connection'] as String?,
        domain: d['domain'] as String?,
        sensitive: d['sensitive'] == true,
        detail: d['detail'] as String? ?? '',
        steps: _strs(d['derivation']),
        confidence: (d['confidence'] as num?)?.toDouble(),
        basis: d['basis'] as String?,
        created: _date(d['created_at']) ?? DateTime.now(),
        confirmed: _date(d['confirmed_at']),
      );

  static Map<String, Object?> _proposalDoc(String uid, Pending p) => {
        'user_id': uid,
        'app_id': p.conn ?? p.source,
        'kind': 'proposal',
        'payload': {
          'pending_id': p.id,
          'layer': p.layer,
          'statement': p.text,
          'prompt': p.prompt,
          'source': p.source,
          'connection': p.conn,
          'mem_id': p.memId,
          'domain': p.domain,
          'sensitive': p.sensitive,
          'confidence': p.conf,
          'basis': p.basis,
          'steps': p.steps,
        },
      };

  /// Also reads proposals a connected app left (they have no `pending_id`).
  static Pending _pendingFrom(String docId, Map<String, Object?> p) => Pending(
        id: p['pending_id'] as String? ?? docId,
        layer: p['layer'] as String? ?? 'pattern',
        text: p['statement'] as String? ?? '',
        prompt: p['prompt'] as String? ?? '',
        source: p['source'] as String? ?? 'crossapp',
        conn: p['connection'] as String?,
        memId: p['mem_id'] as String?,
        domain: p['domain'] as String?,
        sensitive: p['sensitive'] == true,
        conf: (p['confidence'] as num?)?.toDouble(),
        basis: p['basis'] as String?,
        steps: _strs(p['steps']),
      );

  static const _connGrantKeys = ['user_id', 'app_id', 'app_name', 'duration', 'granted_at', 'revoked_at', 'allowed_memory_ids'];
  static const _externalGrantKeys = ['user_id', 'app_id', 'app_name', 'kind', 'duration', 'scopes', 'granted_at', 'revoked_at'];

  static Map<String, Object?> _pick(Map<String, Object?> d, List<String> keys) => {for (final k in keys) k: d[k]};

  static String _logKey(LogEntry l) => '${l.at.toUtc().microsecondsSinceEpoch}|${l.text}';
  static String _short(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 8);

  static String _iso(DateTime t) => t.toUtc().toIso8601String();
  static String? _isoOrNull(DateTime? t) => t == null ? null : _iso(t);
  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v)?.toLocal() : null);
  static List<String> _strs(Object? v) => [for (final x in (v as List? ?? const [])) '$x'];

  /// Structural equality that ignores map key order and int/double spelling.
  static bool _deepEq(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEq(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEq(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}

/// What Firestore holds for one account, as far as this store knows.
class _Remote {
  AccountData data = const AccountData(connsOn: defaultConns);
  bool userExists = false;

  /// Set when a write was rejected: re-read everything before the next save.
  bool stale = false;

  /// Compared content by document path.
  final docs = <String, Map<String, Object?>>{};

  /// Memory id → document id (documents from the first Firebase version have random ids).
  final memDoc = <String, String>{};

  /// Pending id → proposal event document id.
  final pendingDoc = <String, String>{};
  final logKeys = <String>{};
}

class _Op {
  _Op.set(this.path, this.compared, Map<String, Object?> written)
      : data = written,
        logKey = null;
  _Op.delete(this.path)
      : compared = null,
        data = null,
        logKey = null;
  _Op.log(this.logKey, this.path, Map<String, Object?> this.data) : compared = null;

  final String path;
  final Map<String, Object?>? compared, data;
  final String? logKey;

  void apply(FirebaseFirestore db, WriteBatch b) {
    final ref = db.doc(path);
    final d = data;
    if (d == null) {
      b.delete(ref);
    } else if (path.split('/').length == 2 && path.startsWith('users/')) {
      // Leave fields other tools wrote (avatar_url…) alone; replace ours whole.
      b.set(ref, d, SetOptions(mergeFields: d.keys.toList()));
    } else {
      b.set(ref, d);
    }
  }

  void record(_Remote r) {
    if (logKey != null) {
      r.logKeys.add(logKey!);
    } else if (compared == null) {
      r.docs.remove(path);
    } else {
      r.docs[path] = compared!;
      if (path.startsWith('users/') && path.split('/').length == 2) r.userExists = true;
      if (path.startsWith('memories/')) r.memDoc[compared!['mem_id'] as String] = path.substring('memories/'.length);
      if (path.startsWith('events/') && compared!['kind'] == 'proposal') {
        r.pendingDoc[(compared!['payload'] as Map)['pending_id'] as String] = path.substring('events/'.length);
      }
    }
  }
}
