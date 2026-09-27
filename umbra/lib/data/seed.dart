import '../core/format.dart';
import 'models.dart';

/// Demo account content ("Maya"). Dates are relative to [now] so the demo never goes stale.
({List<Memory> mem, List<Pending> pending, List<LogEntry> log}) demoSeed({
  required DateTime now,
  required String name,
  required String role,
  required List<String> topics,
}) {
  DateTime ago(int days, [int h = 20]) {
    final d = now.subtract(Duration(days: days));
    return DateTime(d.year, d.month, d.day, h, 12);
  }

  const ob = ['You chose this during onboarding.', 'Saved directly — you said it.'];
  Memory e(String id, String layer, String text, String detail, List<String> steps, DateTime at, {String? domain, bool sensitive = false}) =>
      Memory(id: id, layer: layer, text: text, source: 'explicit', detail: detail, steps: steps, created: at, confirmed: at, domain: domain, sensitive: sensitive);

  String told(int days) => 'Tell me, ${fmtDate(ago(days))}';

  final mem = <Memory>[
    e('i_name', 'identity', 'Your name is $name.', 'Onboarding', ob, now),
    e('i_role', 'identity', 'You work as a ${role.toLowerCase()}.', 'Onboarding', ob, now),
    e('i_club', 'identity', 'Monthly book club with Jonah and Priya.', told(22),
        ['You wrote: "I’m in a book club with Jonah and Priya."', 'Saved directly as a stable fact.'], ago(22)),
    e('p_topics', 'preference', 'Drawn to ${lowList(topics)}.', 'Onboarding', ob, now),
    e('p_goals', 'preference', 'Goals: learn a new field and finish what I start.', 'Onboarding', ob, now),
    e('p_rhythm', 'preference', '~20-minute sessions, evening.', 'Onboarding', ob, now),
    e('p_format', 'preference', 'Prefers books and articles.', 'Onboarding', ob, now),
    e('p_selfhelp', 'preference', 'No self-help, please.', told(86), ['You wrote: "Please don’t suggest self-help books."', 'Saved directly.'], ago(86)),
    Memory(
        id: 'p_print',
        layer: 'preference',
        text: 'Paper for fiction, digital for nonfiction.',
        source: 'conversational',
        detail: 'Conversation, ${fmtDate(ago(74))}',
        steps: const ['You said: "I can only read novels on paper."', 'Umbra proposed it as a preference.', 'You tapped Keep.'],
        created: ago(74),
        confirmed: ago(74)),
    Memory(
        id: 'pt_evening',
        layer: 'pattern',
        text: 'You read most between 9 and 10:30 pm.',
        source: 'behavioral',
        detail: 'Session start times',
        steps: ['19 sessions logged over 12 days.', '14 started between 9:00 and 10:30 pm.', 'You confirmed it on ${fmtDate(ago(10))}.'],
        created: ago(10),
        confirmed: ago(10),
        confidence: 0.64,
        basis: '12 days of data'),
    Memory(
        id: 'pt_stall',
        layer: 'pattern',
        text: 'Long books tend to stall mid-way.',
        source: 'crossapp',
        conn: 'kindle',
        detail: 'Kindle progress',
        steps: const ['Kindle shared 7 books over 400 pages.', '5 stopped moving between 40% and 60%.', 'Small sample, so confidence stays low.'],
        created: ago(16),
        confirmed: ago(16),
        confidence: 0.42,
        basis: '7 books'),
    Memory(
        id: 'pt_highlight',
        layer: 'pattern',
        text: 'You highlight passages on memory and attention.',
        source: 'crossapp',
        conn: 'kindle',
        detail: 'Kindle highlights',
        steps: ['84 highlights from the last 6 weeks.', '51 relate to memory or attention.', 'You confirmed it on ${fmtDate(ago(13))}.'],
        created: ago(13),
        confirmed: ago(13),
        confidence: 0.73,
        basis: '84 highlights'),
    Memory(
        id: 'pt_commute',
        layer: 'pattern',
        text: 'Podcasts fill your Tue/Thu commutes.',
        source: 'crossapp',
        conn: 'podcasts',
        detail: 'Listening history',
        steps: ['9 weeks of listening times.', 'Plays cluster Tue and Thu, 8–9 am.', 'You confirmed it on ${fmtDate(ago(19))}.'],
        created: ago(19),
        confirmed: ago(19),
        confidence: 0.58,
        basis: '9 weeks'),
    Memory(
        id: 'l_book',
        layer: 'live',
        text: 'Reading The Extended Mind (62%).',
        source: 'crossapp',
        conn: 'kindle',
        detail: 'Kindle progress',
        steps: const ['Kindle reported progress yesterday.', 'You confirmed tracking it.'],
        created: ago(1)),
    Memory(
        id: 'l_talk',
        layer: 'live',
        text: 'Preparing a talk on attention, ${fmtDate(now.add(const Duration(days: 14)))}.',
        source: 'conversational',
        detail: 'Conversation, ${fmtDate(ago(4))}',
        steps: const ['You said: "I’m giving a talk on attention in two weeks."', 'You tapped Keep.'],
        created: ago(4)),
    Memory(
        id: 'l_club',
        layer: 'live',
        text: 'Book club meets ${weekdays[now.add(const Duration(days: 6)).weekday - 1].substring(0, 3)}, ${fmtDate(now.add(const Duration(days: 6)))}.',
        source: 'ambient',
        conn: 'calendar',
        detail: 'Calendar event',
        steps: ['Calendar event "Book club" on ${fmtDate(now.add(const Duration(days: 6)))}.', 'Linked to your book club (Identity).', 'You tapped Keep.'],
        created: ago(2)),
    Memory(
        id: 'mu_evening',
        domain: 'music',
        layer: 'preference',
        text: 'Ambient or jazz to wind down at night.',
        source: 'conversational',
        detail: 'Conversation, ${fmtDate(ago(6))}',
        steps: const ['You said: "Jazz or ambient is how I switch off."', 'Umbra proposed it as a preference.', 'You tapped Keep.'],
        created: ago(6),
        confirmed: ago(6)),
    Memory(
        id: 'mu_focus',
        domain: 'music',
        layer: 'pattern',
        text: 'Instrumental on deep-work days.',
        source: 'behavioral',
        detail: 'Morning check-ins',
        steps: ['9 check-ins where you picked a soundtrack.', 'On 7 of them you also planned deep work.', 'You confirmed it on ${fmtDate(ago(3))}.'],
        created: ago(3),
        confirmed: ago(3),
        confidence: 0.55,
        basis: '9 check-ins'),
    e('h_chrono', 'identity', 'Night owl — sharpest after 8 pm.', told(16), ['You wrote: "I’m a night owl, my brain wakes up after 8."', 'Saved directly as a stable fact.'],
        ago(16),
        domain: 'health', sensitive: true),
    e('h_veg', 'preference', 'Vegetarian. No mushrooms.', told(25), ['You wrote: "Vegetarian, and I can’t stand mushrooms."', 'Saved directly.'], ago(25),
        domain: 'health', sensitive: true),
    Memory(
        id: 'h_walk',
        domain: 'health',
        sensitive: true,
        layer: 'pattern',
        text: 'Energy is higher on days you walk.',
        source: 'behavioral',
        detail: 'Morning check-ins',
        steps: ['11 check-ins with an energy score.', 'Days with a walk averaged 4/5, others 2.8/5.', 'You confirmed it on ${fmtDate(ago(5))}.'],
        created: ago(5),
        confirmed: ago(5),
        confidence: 0.48,
        basis: '11 check-ins'),
  ];

  final sat = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7 == 0 ? 7 : (DateTime.saturday - now.weekday) % 7));
  final pending = <Pending>[
    Pending(
        id: 'q_flight',
        memId: 'l_flight',
        source: 'ambient',
        conn: 'calendar',
        prompt: 'A 3-hour flight on Saturday morning is on your calendar.',
        layer: 'live',
        text: 'Saturday flight: ~3 hours offline.',
        steps: ['Calendar event "LHR → LIS", Sat ${fmtDate(sat)}, 7:40–10:45.']),
    const Pending(
        id: 'q_health',
        domain: 'health',
        sensitive: true,
        source: 'crossapp',
        conn: 'health',
        prompt: 'After nights with 7+ hours of sleep, your sessions ran about 40% longer.',
        layer: 'pattern',
        text: 'You read longer when well rested.',
        conf: 0.46,
        basis: '21 nights',
        steps: ['Apple Health shared sleep duration for 21 nights.', 'Umbra compared it with next-day session length.', 'Only sleep duration is read.']),
    const Pending(
        id: 'q_econ',
        source: 'behavioral',
        prompt: 'You skipped 3 economics articles this week.',
        layer: 'preference',
        text: 'Economics can wait for now.',
        steps: ['"Not now" on 3 economics articles this week.']),
    const Pending(
        id: 'q_sleep',
        source: 'crossapp',
        conn: 'readlater',
        prompt: 'You saved 6 articles about sleep this month.',
        layer: 'pattern',
        text: 'A growing interest in sleep science.',
        conf: 0.52,
        basis: '6 saves in 3 weeks',
        steps: ['Read-later shared 6 articles tagged sleep over 3 weeks.']),
    const Pending(
        id: 'q_library',
        source: 'ambient',
        conn: 'location',
        prompt: 'You opened Umbra at a library three Saturdays running.',
        layer: 'pattern',
        text: 'Saturday mornings may be long-reading time.',
        conf: 0.35,
        basis: '3 Saturdays',
        steps: ['Location: "library" on the last three Saturdays.', 'Only the place type is kept.']),
  ];

  final log = <LogEntry>[
    LogEntry(now, 'Saved what you told me during setup.'),
    LogEntry(ago(1), 'Kindle updated your current book.'),
    LogEntry(ago(4), 'You kept "Preparing a talk on attention".'),
    LogEntry(ago(10), 'You confirmed the evening pattern.'),
  ];
  return (mem: mem, pending: pending, log: log);
}
