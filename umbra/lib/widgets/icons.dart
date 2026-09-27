import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

/// Line icons drawn in a 24×24 box. Each is rendered once (cached by flutter_svg)
/// and tinted with a color filter, so animating colors never re-parses SVG.
class UI {
  const UI(this.body, [this.stroke = 1.8]);
  final String body;
  final double stroke;

  static final _cache = <String, String>{};

  String svg(double sw) => _cache.putIfAbsent('$sw|$body', () {
        return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" '
            'stroke-width="$sw" stroke-linecap="round" stroke-linejoin="round">$body</svg>';
      });

  static const back = UI('<path d="M15 5l-7 7 7 7"/>', 2.3);
  static const close = UI('<path d="M6 6l12 12M18 6L6 18"/>', 2.5);
  static const chevDown = UI('<path d="M6 9l6 6 6-6"/>', 2.5);
  static const chevRight = UI('<path d="M9 6l6 6-6 6"/>', 2.5);
  static const check = UI('<path d="M5 12l5 5 9-10"/>', 3);
  static const checkCircle = UI('<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>', 1.6);
  static const eye = UI('<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>', 1.6);
  static const download = UI('<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>', 1.8);
  static const book = UI('<path d="M4 5.5C4 4.7 4.7 4 5.5 4H11v16H5.5c-.8 0-1.5-.7-1.5-1.5z"/><path d="M20 5.5c0-.8-.7-1.5-1.5-1.5H13v16h5.5c.8 0 1.5-.7 1.5-1.5z"/>', 1.7);
  static const music = UI('<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>', 1.7);
  static const health = UI('<path d="M3 12h4l2-5 4 10 2-5h6"/>', 1.8);
  static const core = UI('<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/>', 1.8);
  static const grid = UI(
      '<rect x="4" y="4" width="6.5" height="6.5" rx="2"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="2"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="2"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="2"/>',
      1.8);
  static const sun = UI('<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>', 1.9);
  static const flame = UI('<path fill="#000" stroke="none" d="M12 2c1 4 6 6 6 12a6 6 0 0 1-12 0c0-3 2-5 3-6 0 2 1 3 2 3 0-4-1-6 1-9z"/>');
  static const bolt = UI('<path fill="#000" stroke="none" d="M13 2L4 14h7l-1 8 9-12h-7z"/>');
  static const play = UI('<path fill="#000" stroke="none" d="M7 4l13 8-13 8z"/>');
  static const star = UI('<path fill="#000" stroke="none" d="M12 2l2.9 6.9 7.1.6-5.4 4.7 1.6 7L12 17.5 5.8 21.2l1.6-7L2 9.5l7.1-.6z"/>');
  static const moon = UI('<path d="M18 15.5A7 7 0 1 1 10 5a5.5 5.5 0 0 0 8 10.5z"/>', 1.9);
  static const halfMoon = UI('<circle cx="12" cy="12" r="7"/><path d="M12 5a7 7 0 0 1 0 14z" fill="#000"/>', 1.9);
  static const fullMoon = UI('<circle cx="12" cy="12" r="7" fill="#000"/>', 1.9);
  static const speaker = UI('<path d="M11 5L6 9H3v6h3l5 4z"/>', 1.9);
  static const wave = UI('<path d="M2 12c2-3 4-3 6 0s4 3 6 0 4-3 6 0"/>', 1.9);
  static const mic = UI('<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>', 1.9);
  static const clock = UI('<circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/>', 1.9);
  static const search = UI('<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>', 2);
  static const person = UI('<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>', 1.8);
  static const heart = UI('<path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z"/>', 1.8);
  static const sparkle = UI('<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/>', 1.8);
  static const sparkles =
      UI('<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M19 17l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z"/>', 1.8);
  static const plus = UI('<path d="M12 5v14M5 12h14"/>', 2.3);
  static const lock = UI('<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>', 2);
  static const edit = UI('<path d="M4 20h4L19 9l-4-4L4 16z"/>', 1.8);
  static const shield = UI('<path d="M12 3l7 3v6c0 4.2-3 7.4-7 9-4-1.6-7-4.8-7-9V6z"/>', 2);
  static const shieldCheck = UI('<path d="M12 3l7 3v6c0 4.2-3 7.4-7 9-4-1.6-7-4.8-7-9V6z"/><path d="M9 12l2 2 4-4"/>', 1.7);
  static const sliders = UI('<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>', 1.8);
  static const doc = UI('<path d="M6 3h9l4 4v14H6z"/><path d="M9 11h7M9 15h7"/>', 1.8);
  static const trash = UI('<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>', 1.8);
  static const signOut = UI('<path d="M15 4h4v16h-4M10 8l-4 4 4 4M6 12h10"/>', 1.8);
  static const send = UI('<path d="M12 19V5M6 11l6-6 6 6"/>', 2.2);
  static const swap = UI('<path d="M4 9h14l-3.5-3.5M20 15H6l3.5 3.5"/>', 2);
  static const chat = UI('<path d="M5 5h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H10l-5 4v-4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/>', 1.8);
  static const food = UI('<path d="M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10M17 21V3c-2 1-3 3-3 6s1 4 3 4"/>', 1.6);
  static const film = UI('<rect x="3" y="8" width="18" height="12" rx="2"/><path d="M3 8l3-4h4l-3 4M10 8l3-4h4l-3 4"/>', 1.6);
  static const travel = UI('<path d="M22 2L11 13M22 2l-7 20-4-9-9-4z"/>', 1.6);
  static const style = UI('<path d="M10 6a2 2 0 1 1 2 2v2l9 7H3l9-7"/>', 1.6);

  // bottom navigation
  static const navToday = UI('<path d="M3 18h18"/><path d="M6.5 18a5.5 5.5 0 0 1 11 0"/><path d="M12 6.5V4.5M5.9 9.4 4.5 8M18.1 9.4 19.5 8"/>', 1.7);
  static const navMemory = UI('<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.4" fill="#000"/>', 1.7);
  static const navYou = UI('<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20.5c1.4-3.8 4.3-5.8 7.5-5.8s6.1 2 7.5 5.8"/>', 1.7);

  // games
  static const puzzle = UI('<path d="M5 5h5a2 2 0 1 1 4 0h5v5a2 2 0 1 0 0 4v5h-5a2 2 0 1 0-4 0H5v-5a2 2 0 1 1 0-4z"/>', 2);
  static const dice = UI(
      '<rect x="4" y="4" width="16" height="16" rx="4"/><circle cx="9" cy="9" r="1.3" fill="#000"/><circle cx="15" cy="15" r="1.3" fill="#000"/><circle cx="15" cy="9" r="1.3" fill="#000"/><circle cx="9" cy="15" r="1.3" fill="#000"/><circle cx="12" cy="12" r="1.3" fill="#000"/>',
      2);
  static const rocket = UI('<path d="M12 2c4 3 5.5 8 3 13H9C6.5 10 8 5 12 2z"/><circle cx="12" cy="9" r="2"/><path d="M9 15l-3 4 4-1M15 15l3 4-4-1M12 18v3"/>', 2);
  static const cards = UI(
      '<rect x="3" y="7" width="10" height="14" rx="2" transform="rotate(-10 8 14)"/><rect x="11" y="3" width="10" height="14" rx="2"/><path d="M16 8l1.5 2-1.5 2-1.5-2z" fill="#000"/>',
      2);
  static const joy = UI('<rect x="3" y="14" width="18" height="7" rx="3"/><path d="M12 14V9"/><circle cx="12" cy="6" r="3"/><circle cx="17" cy="17.5" r="1" fill="#000"/>', 2);
  static const ball = UI('<circle cx="12" cy="12" r="9"/><path d="M12 7.5l4 2.9-1.5 4.6h-5L8 10.4z"/><path d="M12 3v4.5M16 10.4l4.3-1.4M14.5 15l2.7 3.7M9.5 15l-2.7 3.7M8 10.4L3.7 9"/>', 2);

  static UI forGame(String id) => switch (id) {
        'puzzle' => puzzle,
        'dice' => dice,
        'rocket' => rocket,
        'cards' => cards,
        'joy' => joy,
        _ => ball,
      };

  static UI forDomain(String id) => switch (id) {
        'reading' => book,
        'music' => music,
        'health' => health,
        'core' => core,
        _ => grid,
      };

  static UI forLayer(String id) => switch (id) {
        'identity' => person,
        'preference' => heart,
        'pattern' => sparkles,
        _ => clock,
      };
}

class UIcon extends StatelessWidget {
  const UIcon(this.icon, {super.key, this.size = 16, this.color = C.ink, this.stroke});
  final UI icon;
  final double size;
  final Color color;
  final double? stroke;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        icon.svg(stroke ?? icon.stroke),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        excludeFromSemantics: true,
      );
}

/// Multi-colored glyph rendered straight from an SVG string (no tint).
class SetirGlyph extends StatelessWidget {
  const SetirGlyph({super.key, required this.svg, this.size = 22});
  final String svg;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, width: size, height: size, excludeFromSemantics: true);
}
