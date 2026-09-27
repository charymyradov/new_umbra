/// Plain, immutable records that make up a person's memory.
library;

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v as String);

class Memory {
  const Memory({
    required this.id,
    required this.layer,
    required this.text,
    required this.source,
    required this.detail,
    required this.steps,
    required this.created,
    this.confirmed,
    this.conn,
    this.domain,
    this.sensitive = false,
    this.confidence,
    this.basis,
  });

  final String id, layer, text, source, detail;
  final String? conn, domain, basis;
  final bool sensitive;
  final List<String> steps;
  final DateTime created;
  final DateTime? confirmed;
  final double? confidence;

  /// Domain a memory belongs to; onboarding facts are "core", untagged items default to reading.
  String get dom => domain ?? (id == 'i_name' || id == 'i_role' ? 'core' : 'reading');

  Memory copyWith({String? text, DateTime? confirmed, List<String>? steps}) => Memory(
        id: id,
        layer: layer,
        text: text ?? this.text,
        source: source,
        detail: detail,
        steps: steps ?? this.steps,
        created: created,
        confirmed: confirmed ?? this.confirmed,
        conn: conn,
        domain: domain,
        sensitive: sensitive,
        confidence: confidence,
        basis: basis,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'layer': layer,
        'text': text,
        'source': source,
        'detail': detail,
        'steps': steps,
        'created': created.toIso8601String(),
        if (confirmed != null) 'confirmed': confirmed!.toIso8601String(),
        if (conn != null) 'conn': conn,
        if (domain != null) 'domain': domain,
        if (sensitive) 'sensitive': true,
        if (confidence != null) 'confidence': confidence,
        if (basis != null) 'basis': basis,
      };

  factory Memory.fromJson(Map<String, Object?> j) => Memory(
        id: j['id'] as String,
        layer: j['layer'] as String,
        text: j['text'] as String,
        source: j['source'] as String,
        detail: (j['detail'] as String?) ?? '',
        steps: [for (final s in (j['steps'] as List? ?? const [])) s as String],
        created: _date(j['created']) ?? DateTime.now(),
        confirmed: _date(j['confirmed']),
        conn: j['conn'] as String?,
        domain: j['domain'] as String?,
        sensitive: j['sensitive'] == true,
        confidence: (j['confidence'] as num?)?.toDouble(),
        basis: j['basis'] as String?,
      );
}

/// Something Umbra noticed that waits for the person's OK before it is stored.
class Pending {
  const Pending({
    required this.id,
    required this.source,
    required this.prompt,
    required this.layer,
    required this.text,
    this.steps = const [],
    this.memId,
    this.conn,
    this.domain,
    this.sensitive = false,
    this.conf,
    this.basis,
  });

  final String id, source, prompt, layer, text;
  final String? memId, conn, domain, basis;
  final bool sensitive;
  final double? conf;
  final List<String> steps;

  Map<String, Object?> toJson() => {
        'id': id,
        'source': source,
        'prompt': prompt,
        'layer': layer,
        'text': text,
        'steps': steps,
        if (memId != null) 'memId': memId,
        if (conn != null) 'conn': conn,
        if (domain != null) 'domain': domain,
        if (sensitive) 'sensitive': true,
        if (conf != null) 'conf': conf,
        if (basis != null) 'basis': basis,
      };

  factory Pending.fromJson(Map<String, Object?> j) => Pending(
        id: j['id'] as String,
        source: j['source'] as String,
        prompt: j['prompt'] as String,
        layer: j['layer'] as String,
        text: j['text'] as String,
        steps: [for (final s in (j['steps'] as List? ?? const [])) s as String],
        memId: j['memId'] as String?,
        conn: j['conn'] as String?,
        domain: j['domain'] as String?,
        sensitive: j['sensitive'] == true,
        conf: (j['conf'] as num?)?.toDouble(),
        basis: j['basis'] as String?,
      );
}

class LogEntry {
  const LogEntry(this.at, this.text);
  final DateTime at;
  final String text;

  Map<String, Object?> toJson() => {'at': at.toIso8601String(), 'text': text};
  factory LogEntry.fromJson(Map<String, Object?> j) => LogEntry(_date(j['at']) ?? DateTime.now(), j['text'] as String);
}

class ChatMsg {
  const ChatMsg(this.mine, this.text);
  final bool mine;
  final String text;
}

/// An answer collected during a quiz, before the person commits it.
class QuizItem {
  const QuizItem({required this.id, required this.layer, required this.text, required this.domain, required this.sensitive, required this.q, required this.a});
  final String id, layer, text, domain, q, a;
  final bool sensitive;
}

/// An outside app (e.g. LitList) the person signed into with their Umbra account.
class LinkedApp {
  const LinkedApp({required this.scopes, required this.since});

  /// What the person agreed to share, from `kScopeCatalog`.
  final List<String> scopes;
  final DateTime since;

  Map<String, Object?> toJson() => {'scopes': scopes, 'since': since.toIso8601String()};
  factory LinkedApp.fromJson(Map<String, Object?> j) =>
      LinkedApp(scopes: [for (final s in (j['scopes'] as List? ?? const [])) s as String], since: _date(j['since']) ?? DateTime.now());
}

/// Everything stored for one account. Immutable: every change produces a new instance.
class AccountData {
  const AccountData({
    this.onboarded = false,
    this.ob = 1,
    this.name = '',
    this.role = '',
    this.chosenDomains = const ['reading', 'music', 'health'],
    this.mech = defaultMech,
    this.connsOn = const {},
    this.mem = const [],
    this.pending = const [],
    this.sugg = const {},
    this.suggDay,
    this.log = const [],
    this.morningAsked = false,
    this.questsDone = const {},
    this.xp = 0,
    this.streak = 0,
    this.pulse = const {},
    this.lastCheckIn,
    this.healthExport = false,
    this.topics = const [],
    this.times = const [],
    this.formats = const [],
    this.openL = const {},
    this.linked = const {},
  });

  static const defaultMech = {'explicit': true, 'behavioral': true, 'conversational': true, 'ambient': true, 'crossapp': true};

  final bool onboarded, morningAsked, healthExport;
  final int ob, xp, streak;
  final String name, role;
  /// Reading profile from the reading quiz; connected apps read it structurally.
  final List<String> chosenDomains, topics, times, formats;
  final Map<String, bool> mech, connsOn, openL;
  final List<Memory> mem;
  final List<Pending> pending;
  final Map<String, String> sugg, pulse;
  final DateTime? suggDay, lastCheckIn;
  final List<LogEntry> log;
  final Set<String> questsDone;

  /// Connected outside apps by id.
  final Map<String, LinkedApp> linked;

  AccountData copyWith({
    bool? onboarded,
    int? ob,
    String? name,
    String? role,
    List<String>? chosenDomains,
    Map<String, bool>? mech,
    Map<String, bool>? connsOn,
    List<Memory>? mem,
    List<Pending>? pending,
    Map<String, String>? sugg,
    DateTime? suggDay,
    List<LogEntry>? log,
    bool? morningAsked,
    Set<String>? questsDone,
    int? xp,
    int? streak,
    Map<String, String>? pulse,
    DateTime? lastCheckIn,
    bool? healthExport,
    List<String>? topics,
    List<String>? times,
    List<String>? formats,
    Map<String, bool>? openL,
    Map<String, LinkedApp>? linked,
  }) =>
      AccountData(
        onboarded: onboarded ?? this.onboarded,
        ob: ob ?? this.ob,
        name: name ?? this.name,
        role: role ?? this.role,
        chosenDomains: chosenDomains ?? this.chosenDomains,
        mech: mech ?? this.mech,
        connsOn: connsOn ?? this.connsOn,
        mem: mem ?? this.mem,
        pending: pending ?? this.pending,
        sugg: sugg ?? this.sugg,
        suggDay: suggDay ?? this.suggDay,
        log: log ?? this.log,
        morningAsked: morningAsked ?? this.morningAsked,
        questsDone: questsDone ?? this.questsDone,
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        pulse: pulse ?? this.pulse,
        lastCheckIn: lastCheckIn ?? this.lastCheckIn,
        healthExport: healthExport ?? this.healthExport,
        topics: topics ?? this.topics,
        times: times ?? this.times,
        formats: formats ?? this.formats,
        openL: openL ?? this.openL,
        linked: linked ?? this.linked,
      );

  Map<String, Object?> toJson() => {
        'onboarded': onboarded,
        'ob': ob,
        'name': name,
        'role': role,
        'domains': chosenDomains,
        'mech': mech,
        'conns': connsOn,
        'mem': [for (final m in mem) m.toJson()],
        'pending': [for (final p in pending) p.toJson()],
        'sugg': sugg,
        if (suggDay != null) 'suggDay': suggDay!.toIso8601String(),
        'log': [for (final l in log.take(200)) l.toJson()],
        'morningAsked': morningAsked,
        'quests': questsDone.toList(),
        'xp': xp,
        'streak': streak,
        'pulse': pulse,
        if (lastCheckIn != null) 'lastCheckIn': lastCheckIn!.toIso8601String(),
        'healthExport': healthExport,
        'topics': topics,
        'times': times,
        'formats': formats,
        'openL': openL,
        'linked': {for (final e in linked.entries) e.key: e.value.toJson()},
      };

  factory AccountData.fromJson(Map<String, Object?> j, {required Map<String, bool> defaultConns}) {
    Map<String, bool> bools(Object? v, Map<String, bool> def) => {...def, ...?(v as Map?)?.map((k, v) => MapEntry(k as String, v == true))};
    Map<String, String> strMap(Object? v) => (v as Map?)?.map((k, v) => MapEntry(k as String, v as String)) ?? const {};
    List<String> strs(Object? v) => [for (final x in (v as List? ?? const [])) x as String];
    List<Map<String, Object?>> maps(Object? v) => [for (final x in (v as List? ?? const [])) Map<String, Object?>.from(x as Map)];
    return AccountData(
      // v3 files stored `screen`; anything other than onboarding meant the app.
      onboarded: j['onboarded'] as bool? ?? (j['screen'] != null && j['screen'] != 'onboarding'),
      ob: (j['ob'] as num?)?.toInt() ?? 1,
      name: j['name'] as String? ?? '',
      role: j['role'] as String? ?? '',
      chosenDomains: strs(j['domains']),
      mech: {...bools(j['mech'], defaultMech), 'explicit': true},
      connsOn: bools(j['conns'], defaultConns),
      mem: [for (final m in maps(j['mem'])) Memory.fromJson(m)],
      pending: [for (final p in maps(j['pending'])) Pending.fromJson(p)],
      sugg: strMap(j['sugg']),
      suggDay: _date(j['suggDay']),
      log: [for (final l in maps(j['log'])) LogEntry.fromJson(l)],
      morningAsked: j['morningAsked'] == true,
      questsDone: strs(j['quests']).toSet(),
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      streak: (j['streak'] as num?)?.toInt() ?? 0,
      pulse: strMap(j['pulse']),
      lastCheckIn: _date(j['lastCheckIn']),
      healthExport: j['healthExport'] == true,
      topics: strs(j['topics']),
      times: strs(j['times']),
      formats: strs(j['formats']),
      openL: bools(j['openL'], const {}),
      linked: {for (final e in ((j['linked'] as Map?) ?? const {}).entries) e.key as String: LinkedApp.fromJson(Map<String, Object?>.from(e.value as Map))},
    );
  }
}
