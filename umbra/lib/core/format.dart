/// Small text/date helpers shared by every layer.
library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

int daysBetween(DateTime a, DateTime b) => dayOf(b).difference(dayOf(a)).inDays;

/// Relative label for activity rows: Today / Yesterday / Sep 23.
String dayLabel(DateTime d, DateTime now) {
  final n = daysBetween(d, now);
  if (n <= 0) return 'Today';
  if (n == 1) return 'Yesterday';
  return fmtDate(d);
}

/// "a, b and c"
String listJoin(List<String> a) {
  if (a.isEmpty) return '';
  if (a.length == 1) return a.first;
  return '${a.sublist(0, a.length - 1).join(', ')} and ${a.last}';
}

String lowList(List<String> a) => listJoin(a.map((x) => x.toLowerCase()).toList());

String clip(String t, [int n = 34]) => t.length > n ? '${t.substring(0, n - 2)}…' : t;

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

String confWord(double c) => c < 0.45 ? 'Low' : (c < 0.7 ? 'Moderate' : 'Fairly high');

