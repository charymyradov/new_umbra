import 'dart:math';

import '../core/format.dart';
import '../data/catalog.dart';
import '../data/models.dart';

/// Live memories delete themselves after this many days.
const expiryDays = 7;

/// Preferences ask "still true?" after this many days.
const staleDays = 60;

/// Pure read-only rules over an account.
extension AccountRules on AccountData {
  /// Whether a memory/signal from [source] (and optional connection) may be shown or stored.
  /// A connection is either a data source (Kindle…) or an app signed in with Umbra (LitList).
  bool allowed(String source, String? conn) =>
      source == 'explicit' || ((mech[source] ?? false) && (conn == null || (connsOn[conn] ?? linked.containsKey(conn))));

  bool connLive(Conn c) => (connsOn[c.id] ?? false) && (mech[c.mech] ?? false);

  List<Conn> get liveConns => conns.where(connLive).toList();

  List<Pending> get pendingVisible => pending.where((p) => allowed(p.source, p.conn)).toList();

  bool pulseDoneOn(DateTime now) => lastCheckIn != null && daysBetween(lastCheckIn!, now) == 0;

  int count(bool Function(Memory) f) => mem.where(f).length;

  bool has(String id) => mem.any((m) => m.id == id);

  Memory? memById(String? id) {
    if (id == null) return null;
    for (final m in mem) {
      if (m.id == id) return m;
    }
    return null;
  }

  int domainDepth(String d) => min(100, count((m) => m.dom == d) * 5 + (questsDone.contains(d) ? 30 : 0));

  List<Memory> get exportable => mem.where((m) => healthExport || !m.sensitive).toList();
}

DateTime expiresAt(Memory m) => m.created.add(const Duration(days: expiryDays));

int daysLeft(Memory m, DateTime now) => max(0, (expiresAt(m).difference(now).inHours / 24).ceil());

bool isStale(Memory m, DateTime now) => m.layer == 'preference' && m.confirmed != null && daysBetween(m.confirmed!, now) > staleDays;
