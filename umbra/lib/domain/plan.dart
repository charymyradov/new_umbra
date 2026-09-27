import 'package:flutter/painting.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import 'rules.dart';

/// A suggestion resolved against the current memory.
class PlanItem {
  const PlanItem(this.s, this.used, {required this.done});
  final Suggestion s;
  final List<Memory> used;
  final bool done;
  bool get pattern => used.any((m) => m.layer == 'pattern');
  bool get inferred => used.any((m) => m.source != 'explicit');
  String get basisText => pattern
      ? 'Suggested from a pattern, not something you told me.'
      : inferred
          ? 'Based on a signal you confirmed.'
          : 'Based on what you told me.';
}

/// Today's plan: every suggestion whose required memories exist and that wasn't dismissed today.
List<PlanItem> buildPlan(AccountData a) {
  final byId = {for (final m in a.mem) m.id: m};
  final out = <PlanItem>[];
  for (final s in _suggestionDefs(a)) {
    if (a.sugg[s.id] == 'hidden') continue;
    if (!s.needs.every((g) => g.any(byId.containsKey))) continue;
    out.add(PlanItem(s, [for (final id in s.uses) ?byId[id]], done: a.sugg[s.id] == 'done'));
  }
  return out;
}

List<Suggestion> _suggestionDefs(AccountData a) {
  final short = a.has('l_short') || a.pending.any((p) => p.memId == 'l_short') || a.pulse['sleep'] == 'Rough';
  final firstTopic = a.topics.isNotEmpty ? a.topics.first.toLowerCase() : 'something new';
  final evening = a.has('pt_evening');
  return [
    Suggestion(
        id: 's_book',
        needs: const [
          ['l_book']
        ],
        uses: const ['l_book', 'pt_evening', 'p_rhythm', 'l_short', 'l_p_sleep'],
        when: evening ? 'Tonight, 9 pm' : 'This evening',
        hour: evening ? 21 : 19.5,
        title: 'The Extended Mind',
        author: 'Annie Murphy Paul',
        kind: 'Book',
        mins: short ? '15 min' : '25 min',
        sub: short ? 'Chapter 7, first part · 15 min' : 'Chapter 7 · 25 min',
        prog: '62%',
        cbg: const Color(0xFF33486A),
        cfg: const Color(0xFFF1E6D0)),
    Suggestion(
        id: 's_pages',
        needs: const [
          ['q_reading_when', 'q_reading_amount', 'q_reading_genre', 'q_reading_medium']
        ],
        uses: const ['q_reading_when', 'q_reading_amount', 'q_reading_genre', 'q_reading_medium', 'l_p_sleep'],
        when: 'This evening',
        hour: 19.5,
        title: 'Twenty quiet pages',
        author: 'Your current book',
        kind: 'Book',
        mins: short ? '10 min' : '20 min',
        sub: short ? 'A short sitting · 10 min' : 'Phone in another room · 20 min',
        cbg: const Color(0xFF7A3B2E),
        cfg: const Color(0xFFF3E3CF)),
    const Suggestion(
        id: 's_club',
        needs: [
          ['i_club'],
          ['l_club']
        ],
        uses: ['i_club', 'l_club'],
        when: 'Before book club',
        hour: null,
        title: 'Piranesi',
        author: 'Susanna Clarke',
        kind: 'Book club',
        mins: '90 min',
        sub: 'Chapters 1–4 · over 3 evenings',
        cbg: Color(0xFF7A3B2E),
        cfg: Color(0xFFF3E3CF)),
    const Suggestion(
        id: 's_play',
        needs: [
          ['mu_evening', 'q_music_genres', 'q_music_moments', 'l_p_sound']
        ],
        uses: ['mu_evening', 'mu_focus', 'l_p_sound', 'q_music_genres', 'q_music_moments'],
        when: 'Before reading',
        hour: 20,
        title: 'Wind-down mix',
        author: 'Ambient + jazz',
        kind: 'Playlist',
        mins: '30 min',
        sub: 'Ambient and jazz · 30 min',
        cbg: Color(0xFF5B4163),
        cfg: Color(0xFFF0E4EC)),
    const Suggestion(
        id: 's_walk',
        needs: [
          ['h_walk', 'q_health_move', 'l_p_energy']
        ],
        uses: ['h_walk', 'h_chrono', 'l_p_energy', 'q_health_move', 'q_health_chrono'],
        when: 'After lunch',
        hour: 13.5,
        title: 'A 15-minute walk',
        author: 'Movement',
        kind: 'Move',
        mins: '15 min',
        sub: 'Energy tends to lift after · 15 min',
        cbg: Color(0xFF2F6F73),
        cfg: Color(0xFFDDEDEC)),
    if (!a.has('l_break'))
      const Suggestion(
          id: 's_talk',
          needs: [
            ['l_talk']
          ],
          uses: ['l_talk', 'pt_highlight'],
          when: 'Today',
          hour: 16,
          title: 'The Myth of Multitasking',
          author: 'Read-later',
          kind: 'Long read',
          mins: '18 min',
          sub: 'For your talk · 18 min',
          cbg: Color(0xFFC9A45C),
          cfg: Color(0xFF2B2620)),
    const Suggestion(
        id: 's_flight',
        needs: [
          ['l_flight']
        ],
        uses: ['l_flight', 'pt_stall'],
        when: 'Saturday flight',
        hour: null,
        title: 'Three short essays',
        author: 'Offline pack',
        kind: 'Essays',
        mins: '2.5 hr',
        sub: 'Saved offline · 2.5 hr',
        cbg: Color(0xFF4B6A42),
        cfg: Color(0xFFEFEAD8)),
    const Suggestion(
        id: 's_pod',
        needs: [
          ['pt_commute']
        ],
        uses: ['pt_commute'],
        when: 'Tue commute',
        hour: 8.5,
        title: 'Why we forget',
        author: 'Hidden Brain',
        kind: 'Podcast',
        mins: '42 min',
        sub: 'Podcast · 42 min',
        cbg: Color(0xFF5B4163),
        cfg: Color(0xFFF0E4EC)),
    Suggestion(
        id: 's_new',
        needs: const [
          ['p_topics', 'q_reading_topics']
        ],
        uses: const ['p_topics', 'p_goals', 'q_reading_topics'],
        when: 'Anytime',
        hour: 11.5,
        title: 'Intro to $firstTopic',
        author: 'Primer',
        kind: 'Article',
        mins: '12 min',
        sub: 'Something new · 12 min',
        cbg: const Color(0xFFD8CBB3),
        cfg: const Color(0xFF2B2620)),
  ];
}
