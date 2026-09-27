/// Static catalogue: memory layers, learning sources, connected apps, domains,
/// quizzes, games and suggestion templates.
library;

import 'package:flutter/material.dart';

import '../core/format.dart';

// ───────────────────────── learning mechanisms ─────────────────────────

class Src {
  const Src(this.code, this.name, this.short, this.color);
  final String code, name, short;
  final Color color;
}

const src = <String, Src>{
  'explicit': Src('a', 'Told directly', 'Saves directly', Color(0xFF2B2620)),
  'behavioral': Src('b', 'In-app behavior', 'What you start or skip', Color(0xFF8A5A1F)),
  'conversational': Src('c', 'Conversation', 'Things you mention', Color(0xFF7A3B2E)),
  'ambient': Src('d', 'Passive signals', 'Calendar, place type', Color(0xFF4B6A42)),
  'crossapp': Src('e', 'Connected apps', 'Kindle, podcasts, more', Color(0xFF33486A)),
};

const mechOrder = ['explicit', 'behavioral', 'conversational', 'ambient', 'crossapp'];

// ───────────────────────── memory layers ─────────────────────────

enum ShapeKind { square, dot, ring, dashedRing }

class LayerDef {
  const LayerDef({
    required this.id,
    required this.name,
    required this.tag,
    required this.color,
    required this.bg,
    required this.shape,
    required this.shapeColor,
    required this.empty,
    required this.plain,
    required this.dark,
    required this.ringInset,
    required this.addPh,
  });
  final String id, name, tag, empty, plain, addPh;
  final Color color, bg, shapeColor, dark;
  final ShapeKind shape;
  final double ringInset;

  /// Color used for a basis dot (filled shapes use their fill, outlines their ink).
  Color get dotColor => shape == ShapeKind.square || shape == ShapeKind.dot ? shapeColor : color;
}

const layers = <LayerDef>[
  LayerDef(
      id: 'identity',
      name: 'Identity',
      tag: 'Stable',
      color: Color(0xFF2B2620),
      bg: Color(0xFFEAE2D3),
      shape: ShapeKind.square,
      shapeColor: Color(0xFF2B2620),
      empty: 'No stable facts.',
      plain: 'Who you are',
      dark: Color(0xFFE9C98A),
      ringInset: 33,
      addPh: 'e.g. I have a daughter, Ana'),
  LayerDef(
      id: 'preference',
      name: 'Preferences',
      tag: 'Confirmed',
      color: Color(0xFF8A5A1F),
      bg: Color(0xFFF4E7D3),
      shape: ShapeKind.dot,
      shapeColor: Color(0xFFC0772E),
      empty: 'No preferences.',
      plain: 'What you like',
      dark: Color(0xFFE39A7B),
      ringInset: 22,
      addPh: 'e.g. Prefer audiobooks for history'),
  LayerDef(
      id: 'pattern',
      name: 'Patterns',
      tag: 'Probable',
      color: Color(0xFF3D5C7A),
      bg: Color(0xFFE4EAF0),
      shape: ShapeKind.ring,
      shapeColor: Color(0xFF3D5C7A),
      empty: 'No patterns.',
      plain: 'What I’ve noticed',
      dark: Color(0xFF9DB8D3),
      ringInset: 11,
      addPh: 'e.g. I read more on weekends'),
  LayerDef(
      id: 'live',
      name: 'Live',
      tag: 'Temporary',
      color: Color(0xFF4B6A42),
      bg: Color(0xFFE6EDDF),
      shape: ShapeKind.dashedRing,
      shapeColor: Color(0xFF4B6A42),
      empty: 'Nothing current.',
      plain: 'Right now',
      dark: Color(0xFFA9C79B),
      ringInset: 0,
      addPh: 'e.g. Studying for an exam this week'),
];

final layerById = {for (final l in layers) l.id: l};

// ───────────────────────── connected apps ─────────────────────────

class Conn {
  const Conn(this.id, this.name, this.glyph, this.folder, this.mech, this.color, this.fg, this.reads, this.never, this.synced);
  final String id, name, glyph, folder, mech, synced;
  final Color color, fg;
  final List<String> reads, never;
}

const conns = <Conn>[
  Conn('kindle', 'Kindle', 'K', 'reading', 'crossapp', Color(0xFF1F2A36), Color(0xFFF2C27B), ['Reading progress', 'Highlights'], ['Purchases', 'Personal notes'], '2h ago'),
  Conn('books', 'Apple Books', 'B', 'reading', 'crossapp', Color(0xFFE07A2E), Color(0xFFFFF6EC), ['Current books', 'Finished dates'], ['Purchases'], '1h ago'),
  Conn('libby', 'Libby', 'L', 'reading', 'crossapp', Color(0xFF8B3A62), Color(0xFFFCEFF5), ['Loans', 'Holds'], ['Library card'], 'never'),
  Conn('shelf', 'Goodreads', 'g', 'shelves', 'crossapp', Color(0xFF5A4632), Color(0xFFF4EBDD), ['Shelves', 'Ratings'], ['Reviews', 'Friends'], '3d ago'),
  Conn('storygraph', 'StoryGraph', 'S', 'shelves', 'crossapp', Color(0xFF2F6F73), Color(0xFFE9F4F3), ['Moods', 'Pace'], ['Journal'], 'never'),
  Conn('podcasts', 'Apple Podcasts', 'P', 'listening', 'crossapp', Color(0xFF8E4EC6), Color(0xFFF7EFFF), ['Episodes played'], ['Subscriptions list'], 'this morning'),
  Conn('spotify', 'Spotify', 'S', 'listening', 'crossapp', Color(0xFF1F8F4E), Color(0xFFEAF7EF), ['Podcast plays'], ['Music'], 'never'),
  Conn('audible', 'Audible', 'A', 'listening', 'crossapp', Color(0xFFD9822B), Color(0xFF2B2620), ['Listening progress'], ['Purchases'], 'never'),
  Conn('readlater', 'Pocket', 'P', 'saved', 'crossapp', Color(0xFFC8414B), Color(0xFFFFF0F1), ['Saved titles', 'Topics'], ['Article text'], 'yesterday'),
  Conn('safari', 'Reading List', 'R', 'saved', 'crossapp', Color(0xFF2F72C9), Color(0xFFEEF5FF), ['Saved titles'], ['History'], 'never'),
  Conn('notes', 'Notes', 'N', 'saved', 'crossapp', Color(0xFFE8C547), Color(0xFF2B2620), ['#reading notes only'], ['Other notes'], 'never'),
  Conn('calendar', 'Calendar', '31', 'place', 'ambient', Color(0xFFD94F3D), Color(0xFFFFF4F2), ['Event titles', 'Free time'], ['Attendees', 'Notes'], '20m ago'),
  Conn('location', 'Location', 'L', 'place', 'ambient', Color(0xFF4B6A42), Color(0xFFEFEAD8), ['Place type'], ['Addresses', 'Routes'], 'this morning'),
  Conn('health', 'Apple Health', 'H', 'wellbeing', 'crossapp', Color(0xFFE5476A), Color(0xFFFFF0F3), ['Sleep duration', 'Mindful minutes'], ['Heart, body, medical'], 'this morning'),
  Conn('screentime', 'Screen Time', 'T', 'wellbeing', 'ambient', Color(0xFF5B4FBF), Color(0xFFF0EEFF), ['Daily total'], ['Per-app usage'], 'never'),
];

final connById = {for (final c in conns) c.id: c};

const defaultConns = {
  'kindle': true, 'books': true, 'libby': false, 'shelf': true, 'storygraph': false, 'podcasts': true, 'spotify': false, //
  'audible': false, 'readlater': true, 'safari': false, 'notes': false, 'calendar': true, 'location': true, 'health': true, 'screentime': false,
};

class Folder {
  const Folder(this.id, this.name, this.bg);
  final String id, name;
  final Color bg;
}

const folders = <Folder>[
  Folder('reading', 'Reading', Color(0xFFE9E1D2)),
  Folder('shelves', 'Shelves', Color(0xFFEDE2D2)),
  Folder('listening', 'Listening', Color(0xFFE8E3EE)),
  Folder('saved', 'Saved', Color(0xFFF1E3DF)),
  Folder('place', 'Time & place', Color(0xFFE3EADF)),
  Folder('wellbeing', 'Wellbeing', Color(0xFFF2E1E4)),
];

// ───────────────────────── domains ─────────────────────────

class Domain {
  const Domain(this.id, this.name, this.color, this.bg, this.blurb);
  final String id, name, blurb;
  final Color color, bg;
}

const domains = <Domain>[
  Domain('reading', 'Reading', Color(0xFF7A3B2E), Color(0xFFF3E3DC), 'Books, articles, how you read'),
  Domain('music', 'Music', Color(0xFF5B4163), Color(0xFFEDE3EE), 'Genres, moods, when it matters'),
  Domain('health', 'Health', Color(0xFF2F6F73), Color(0xFFDDEDEC), 'Sleep, energy, movement, food'),
];
const coreDomain = Domain('core', 'General', Color(0xFF2B2620), Color(0xFFEAE2D3), '');
final domainById = {for (final d in [...domains, coreDomain]) d.id: d};

const soonDomains = ['Food & groceries', 'Film & TV', 'Travel', 'Style'];

// ───────────────────────── games ─────────────────────────

class Game {
  const Game(this.id, this.name, this.genre, this.color, this.tint, this.icon, this.blurb);
  final String id, name, genre, icon, blurb;
  final Color color, tint;
}

const games = <Game>[
  Game('tangle', 'Tiny Tangle', 'Puzzle', Color(0xFFE8962A), Color(0xFFFBEBD0), 'puzzle', 'Untie knotted ropes in as few moves as you can.'),
  Game('dice', 'Dice Dash', 'Board', Color(0xFFE5476A), Color(0xFFFADCE3), 'dice', 'Roll, race and block your friends on a shrinking board.'),
  Game('orbit', 'Orbit Hop', 'Arcade', Color(0xFF5B4FBF), Color(0xFFE4E1F7), 'rocket', 'Jump between planets without drifting into the dark.'),
  Game('castle', 'Card Castle', 'Cards', Color(0xFF2F8F4E), Color(0xFFD9F0E1), 'cards', 'Stack cards into towers before the wind knocks them down.'),
  Game('pals', 'Pixel Pals', 'Casual', Color(0xFF2F72C9), Color(0xFFDCE8F8), 'joy', 'Raise a tiny pixel creature one mini-game at a time.'),
  Game('goal', 'Goal Rush', 'Sports', Color(0xFFC9731F), Color(0xFFF8E3CC), 'ball', 'One-touch football in thirty-second matches.'),
];

// ───────────────────────── levels ─────────────────────────

const levels = <(int, String)>[(0, 'Stranger'), (150, 'Acquaintance'), (350, 'Friend'), (600, 'Confidant'), (1000, 'Kindred')];

class LevelInfo {
  const LevelInfo(this.index, this.name, this.cur, this.next);
  final int index, cur;
  final int? next;
  final String name;
}

LevelInfo levelFor(int xp) {
  var i = 0;
  for (var j = 0; j < levels.length; j++) {
    if (xp >= levels[j].$1) i = j;
  }
  return LevelInfo(i, levels[i].$2, levels[i].$1, i + 1 < levels.length ? levels[i + 1].$1 : null);
}

// ───────────────────────── quizzes ─────────────────────────

enum QType { duo, multi, scale, swipe, text }

class DuoOpt {
  const DuoOpt(this.label, this.sub, this.bg, this.fg);
  final String label, sub;
  final Color bg, fg;
}

typedef SaveFn = String? Function(String answer, List<String> picked);

class Question {
  const Question({
    required this.id,
    required this.type,
    required this.q,
    this.sub,
    this.max = 99,
    this.layer,
    this.opts = const [],
    this.duo = const [],
    this.items = const [],
    this.ph = '',
    this.save,
  });
  final String id, q, ph;
  final String? sub, layer;
  final QType type;
  final int max;
  final List<String> opts;
  final List<DuoOpt> duo;

  /// Swipe statements: (shown prompt, text saved when "That's me").
  final List<(String, String)> items;
  final SaveFn? save;
}

class Quest {
  const Quest(this.title, this.qs, {this.sensitive = false});
  final String title;
  final bool sensitive;
  final List<Question> qs;
  int get maxXp => qs.length * xpPerAnswer;
}

const xpPerAnswer = 15;
const topicNames = ['Cognitive science', 'Design', 'History', 'Climate', 'Fiction', 'Economics'];
const timeNames = ['Morning', 'Commute', 'Lunch', 'Evening', 'Night'];

final quests = <String, Quest>{
  'reading': Quest('The reader in you', [
    Question(
        id: 'medium',
        type: QType.duo,
        q: 'Pick your page',
        duo: const [
          DuoOpt('Paper', 'Weight, smell, margins', Color(0xFFE9DCC6), Color(0xFF2B2620)),
          DuoOpt('Screen', 'Light, searchable, always there', Color(0xFF2B2620), Color(0xFFF6F1E7)),
        ],
        save: (a, _) => 'Prefers reading on ${a.toLowerCase()}.'),
    Question(
        id: 'genre',
        type: QType.duo,
        q: 'A free evening. You pick…',
        duo: const [
          DuoOpt('A novel', 'Lose yourself in a story', Color(0xFF5B4163), Color(0xFFF0E4EC)),
          DuoOpt('Nonfiction', 'Come away knowing more', Color(0xFF33486A), Color(0xFFF1E6D0)),
        ],
        save: (a, _) => a == 'A novel' ? 'Reaches for fiction on free evenings.' : 'Reaches for nonfiction on free evenings.'),
    Question(id: 'topics', type: QType.multi, q: 'What pulls you in?', sub: 'Up to four.', max: 4, opts: topicNames, save: (_, p) => 'Drawn to ${lowList(p)}.'),
    const Question(id: 'habits', type: QType.swipe, q: 'Me, or not me?', layer: 'pattern', items: [
      ('I finish every book I start', 'Finishes every book they start.'),
      ('I juggle several books at once', 'Reads several books at once.'),
      ('I re-read favourites', 'Re-reads favourites.'),
      ('Audiobooks count as reading', 'Counts audiobooks as reading.'),
    ]),
    Question(
        id: 'amount',
        type: QType.scale,
        q: 'A typical week of reading',
        layer: 'pattern',
        opts: const ['Under an hour', '1–3 hours', '3–5 hours', '5–8 hours', '8+ hours'],
        save: (a, _) => 'Reads ${a.toLowerCase()} a week.'),
    Question(id: 'when', type: QType.multi, q: 'When do you read best?', max: 5, opts: timeNames, save: (_, p) => 'Reads best: ${lowList(p)}.'),
  ]),
  'music': Quest('Your sound', [
    Question(
        id: 'genres',
        type: QType.multi,
        q: 'What’s on repeat?',
        sub: 'Up to four.',
        max: 4,
        opts: const ['Jazz', 'Indie', 'Classical', 'Hip-hop', 'Electronic', 'Folk', 'Pop', 'Rock', 'R&B', 'Ambient', 'Soul', 'Latin'],
        save: (_, p) => 'Listens to ${listJoin(p)}.'),
    Question(
        id: 'focus',
        type: QType.duo,
        q: 'While you focus',
        duo: const [
          DuoOpt('Lyrics', 'Words keep me company', Color(0xFFC0772E), Color(0xFFFFF6EC)),
          DuoOpt('Instrumental', 'Words get in the way', Color(0xFF33486A), Color(0xFFF1E6D0)),
        ],
        save: (a, _) => a == 'Lyrics' ? 'Fine with lyrics while focusing.' : 'Needs instrumental music to focus.'),
    const Question(id: 'habits', type: QType.swipe, q: 'Me, or not me?', layer: 'pattern', items: [
      ('I listen to albums start to finish', 'Listens to whole albums.'),
      ('I loop one song for days', 'Loops a single song for days.'),
      ('Music helps me fall asleep', 'Uses music to fall asleep.'),
      ('I hunt for new artists every week', 'Actively seeks out new artists.'),
    ]),
    Question(
        id: 'moments',
        type: QType.multi,
        q: 'When does music matter most?',
        max: 6,
        opts: const ['Focus', 'Workout', 'Commute', 'Cooking', 'Wind-down', 'Social'],
        save: (_, p) => 'Music matters most for ${lowList(p)}.'),
    Question(
        id: 'energy',
        type: QType.scale,
        q: 'Your usual volume',
        opts: const ['Hushed', 'Mellow', 'Balanced', 'Lively', 'Loud'],
        save: (a, _) => 'Usual listening energy: ${a.toLowerCase()}.'),
    Question(
        id: 'artist',
        type: QType.text,
        q: 'One artist you’d never tire of',
        ph: 'e.g. Nina Simone',
        layer: 'identity',
        save: (a, _) => 'Never tires of $a.'),
  ]),
  'health': Quest('How you feel', sensitive: true, [
    Question(
        id: 'chrono',
        type: QType.duo,
        q: 'Left to your own rhythm',
        layer: 'identity',
        duo: const [
          DuoOpt('Early bird', 'Sharpest before noon', Color(0xFFE9C98A), Color(0xFF2B2620)),
          DuoOpt('Night owl', 'Wakes up after dark', Color(0xFF2B2F4A), Color(0xFFEDE7F5)),
        ],
        save: (a, _) => '$a by nature.'),
    Question(
        id: 'sleep',
        type: QType.scale,
        q: 'A normal night’s sleep',
        layer: 'pattern',
        opts: const ['Under 5 hours', '5–6 hours', '6–7 hours', '7–8 hours', '8+ hours'],
        save: (a, _) => 'Usually sleeps $a.'),
    Question(
        id: 'move',
        type: QType.multi,
        q: 'How do you move?',
        max: 8,
        opts: const ['Walking', 'Running', 'Yoga', 'Gym', 'Cycling', 'Swimming', 'Team sport', 'Dancing', 'Not much yet'],
        save: (_, p) => p.contains('Not much yet') ? 'Wants to move more.' : 'Moves by ${lowList(p)}.'),
    Question(
        id: 'diet',
        type: QType.multi,
        q: 'How do you eat?',
        sub: 'Shapes grocery and recipe ideas later.',
        max: 3,
        opts: const ['No restrictions', 'Vegetarian', 'Vegan', 'Pescatarian', 'Gluten-free', 'Dairy-free', 'Halal', 'Kosher', 'Low sugar'],
        save: (_, p) => 'Eats: ${lowList(p)}.'),
    const Question(id: 'body', type: QType.swipe, q: 'Me, or not me?', layer: 'pattern', items: [
      ('Stress shows up in my sleep', 'Stress affects their sleep.'),
      ('I hit an afternoon slump', 'Gets an afternoon slump.'),
      ('Coffee after 3 pm keeps me up', 'Sensitive to late caffeine.'),
      ('I drink enough water', 'Drinks enough water.'),
    ]),
    Question(
        id: 'cond',
        type: QType.multi,
        q: 'Anything I should keep in mind?',
        sub: 'Optional. Marked private.',
        layer: 'identity',
        max: 8,
        opts: const ['Allergies', 'Asthma', 'Migraines', 'Back pain', 'Diabetes', 'Anxiety', 'Pregnancy', 'Prefer not to say'],
        save: (_, p) => p.contains('Prefer not to say') ? null : 'Keep in mind: ${lowList(p)}.'),
  ]),
};

// ───────────────────────── check-in ─────────────────────────

class PulseRow {
  const PulseRow(this.key, this.label, this.color, this.glow, this.opts);
  final String key, label;
  final Color color, glow;
  final List<String> opts;
}

const pulseRows = <PulseRow>[
  PulseRow('sleep', 'Sleep', Color(0xFF2F6F73), Color(0xFF9FC3C1), ['Rough', 'Okay', 'Great']),
  PulseRow('energy', 'Energy', Color(0xFFC0772E), Color(0xFFE9A94A), ['1', '2', '3', '4', '5']),
  PulseRow('sound', 'Soundtrack', Color(0xFF5B4163), Color(0xFFC9B3D1), ['Quiet', 'Calm', 'Upbeat', 'Podcasts']),
];

// ───────────────────────── suggestions ─────────────────────────

class Suggestion {
  const Suggestion({
    required this.id,
    required this.needs,
    required this.uses,
    required this.when,
    required this.hour,
    required this.title,
    required this.author,
    required this.kind,
    required this.mins,
    required this.sub,
    required this.cbg,
    required this.cfg,
    this.prog,
  });

  /// Every group needs at least one memory id present.
  final List<List<String>> needs;
  final List<String> uses;
  final String id, when, title, author, kind, mins, sub;
  final String? prog;

  /// Hour of day on the sun arc (null → not plotted).
  final double? hour;
  final Color cbg, cfg;

  String get cta => const {'Playlist': 'Play', 'Move': 'Start', 'Podcast': 'Listen'}[kind] ?? 'Start reading';
  String get doneLabel => const {'Playlist': 'Playing', 'Move': 'Started', 'Podcast': 'Listening'}[kind] ?? 'Reading';
  bool get isReading => !const {'Playlist', 'Move', 'Podcast'}.contains(kind);
}

