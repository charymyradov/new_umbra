import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Umbra palette — warm paper tones with ink.
abstract final class C {
  static const ink = Color(0xFF2B2620);
  static const inkDeep = Color(0xFF1E1B17);
  static const inkSoft = Color(0xFF3A352E);
  static const inkLine = Color(0xFF44403A);
  static const paper = Color(0xFFF6F1E7);
  static const card = Color(0xFFFFFDF8);
  static const desk = Color(0xFFE3DACA);
  static const sand = Color(0xFFEEE7D9);
  static const line = Color(0xFFE4DBCB);
  static const dash = Color(0xFFD9CFBD);
  static const muted = Color(0xFF8A8174);
  static const body = Color(0xFF5E564B);
  static const faint = Color(0xFFB5AA99);
  static const onDarkMuted = Color(0xFFBDB3A3);
  static const onDark = Color(0xFFE8E0D2);
  static const gold = Color(0xFFE9C98A);
  static const sun = Color(0xFFE9A94A);
  static const amber = Color(0xFF8A5A1F);
  static const amberBg = Color(0xFFF4E7D3);
  static const staleBg = Color(0xFFF6EBDA);
  static const blue = Color(0xFF3D5C7A);
  static const blueBg = Color(0xFFE4EAF0);
  static const green = Color(0xFF4B6A42);
  static const greenBg = Color(0xFFE6EDDF);
  static const greenOk = Color(0xFFEAF0E3);
  static const teal = Color(0xFF2F6F73);
  static const tealBg = Color(0xFFDDEDEC);
  static const tealLight = Color(0xFF9FC3C1);
  static const red = Color(0xFF8C3B2A);
  static const redBg = Color(0xFFF3E2DC);
  static const toggleOff = Color(0xFFD9CFBD);
  static const toggleOn = Color(0xFF4B6A42);
  static const scrim = Color(0x661E1B17);
}

Color hex(String h) {
  var s = h.replaceFirst('#', '');
  if (s.length == 6) s = 'FF$s';
  return Color(int.parse(s, radix: 16));
}

/// Serif display type (Newsreader).
TextStyle serif(double size, {Color? color, double? height, bool italic = false, double? spacing, FontWeight? weight}) =>
    GoogleFonts.newsreader(
      fontSize: size,
      color: color ?? C.ink,
      height: height,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: spacing == null ? null : spacing * size,
      fontWeight: weight ?? FontWeight.w400,
    );

/// UI sans (Public Sans).
TextStyle sans(double size, {Color? color, FontWeight? weight, double? height, double? spacing}) => GoogleFonts.publicSans(
      fontSize: size,
      color: color ?? C.ink,
      fontWeight: weight ?? FontWeight.w400,
      height: height,
      letterSpacing: spacing == null ? null : spacing * size,
    );

/// Rounded playful type for the games tab (Fredoka).
TextStyle fredoka(double size, {Color? color, FontWeight? weight, double? height}) => GoogleFonts.fredoka(
      fontSize: size,
      color: color ?? C.ink,
      fontWeight: weight ?? FontWeight.w400,
      height: height,
    );

/// Uppercase tracking label.
TextStyle caps(double size, {Color? color, double spacing = .08, FontWeight? weight}) =>
    sans(size, color: color ?? C.muted, spacing: spacing, weight: weight);

const easeOutSoft = Cubic(.2, .8, .2, 1);
const easeSpring = Cubic(.3, 1.6, .5, 1);
const easeSpringStrong = Cubic(.3, 1.8, .5, 1);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.ink, surface: C.paper, primary: C.ink),
    scaffoldBackgroundColor: C.paper,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.ink,
      selectionColor: Color(0x332B2620),
      selectionHandleColor: C.ink,
    ),
  );
  return base.copyWith(textTheme: GoogleFonts.publicSansTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink));
}

List<BoxShadow> shadow(double y, double blur, double spread, Color color) =>
    [BoxShadow(offset: Offset(0, y), blurRadius: blur, spreadRadius: spread, color: color)];
