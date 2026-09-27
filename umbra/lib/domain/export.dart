import 'dart:convert';

import '../core/format.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import 'rules.dart';

/// `umbra.memory/v1` JSON export.
String exportJson(AccountData a, DateTime now) {
  Map<String, Object?> item(Memory m) => {
        'id': m.id,
        'statement': m.text,
        'domain': m.dom,
        'private': m.sensitive,
        'source': {'mechanism': m.source, 'code': src[m.source]!.code, 'label': src[m.source]!.name, 'connection': m.conn, 'detail': m.detail},
        'derivation': m.steps,
        'recorded_at': m.created.toIso8601String(),
        'last_confirmed_at': m.confirmed?.toIso8601String(),
        'confidence': m.confidence == null ? null : {'score': m.confidence, 'label': confWord(m.confidence!), 'basis': m.basis},
        'expires_at': m.layer == 'live' ? expiresAt(m).toIso8601String() : null,
      };
  final ex = a.exportable;
  return const JsonEncoder.withIndent('  ').convert({
    'schema': 'umbra.memory/v1',
    'exported_at': now.toIso8601String(),
    'owner': a.name,
    'private_health_included': a.healthExport,
    'layers': {for (final L in layers) L.id: [for (final m in ex.where((m) => m.layer == L.id)) item(m)]},
    'permissions': {
      for (final k in mechOrder) k: {'enabled': a.mech[k] ?? false, 'stores': k == 'explicit' ? 'directly' : 'after_confirmation'}
    },
    'connections': [for (final c in conns) {'id': c.id, 'name': c.name, 'mechanism': c.mech, 'enabled': a.connsOn[c.id] ?? false}],
    'activity': [for (final l in a.log) {'at': l.at.toIso8601String(), 'text': l.text}],
  });
}

/// Human-readable summary export.
String exportText(AccountData a, DateTime now) {
  final b = StringBuffer()
    ..writeln('What Umbra knows about ${a.name}')
    ..writeln('Exported ${weekdays[now.weekday - 1]}, ${fmtDate(now)} ${now.year}')
    ..writeln();
  final ex = a.exportable;
  for (final L in layers) {
    final items = ex.where((m) => m.layer == L.id).toList();
    b
      ..writeln('${L.name.toUpperCase()} · ${L.tag} (${items.length})')
      ..writeln();
    for (final m in items) {
      final c = m.conn == null ? null : connById[m.conn];
      b
        ..writeln('• ${m.text}')
        ..writeln('  Source: ${src[m.source]!.name}${c != null ? ' · ${c.name}' : ''} — ${m.detail}');
      if (m.layer == 'pattern' && m.confidence != null) b.writeln('  Confidence: ${confWord(m.confidence!)}, based on ${m.basis}');
      if (m.layer == 'live') b.writeln('  Expires: ${daysLeft(m, now)}d left · ${fmtDate(expiresAt(m))}');
      if (m.layer == 'preference' && m.confirmed != null) b.writeln('  Last confirmed ${fmtDate(m.confirmed!)}');
    }
    b.writeln();
  }
  b.writeln('Learning permissions:');
  for (final k in mechOrder) {
    b.writeln('  ${src[k]!.code}) ${src[k]!.name}: ${(a.mech[k] ?? false) ? 'on' : 'off'}');
  }
  return b.toString();
}
