import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../core/theme.dart';
import 'icons.dart';

/// Tap target with a gentle press-scale, like CSS `:active { transform: scale(.97) }`.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = .97, this.label});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Rounded pill button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 52,
    this.bg = C.ink,
    this.fg = C.paper,
    this.border,
    this.fontSize = 15,
    this.weight = FontWeight.w500,
    this.icon,
    this.enabled = true,
    this.expand = true,
    this.padding = 18,
  });
  final String label;
  final VoidCallback? onTap;
  final double height, fontSize, padding;
  final Color bg, fg;
  final Color? border;
  final FontWeight weight;
  final Widget? icon;
  final bool enabled, expand;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(fontSize, color: fg, weight: weight))),
      ],
    );
    return Pressable(
      onTap: enabled ? onTap : null,
      label: label,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Plain text button (no background).
class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, this.onTap, this.color = C.body, this.size = 14, this.height = 44, this.weight});
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size, height;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        label: label,
        child: SizedBox(
          height: height,
          child: Center(child: Text(label, style: sans(size, color: color, weight: weight))),
        ),
      );
}

/// Round icon button (close, back, etc).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 34,
    this.iconSize = 12,
    this.bg = C.card,
    this.fg = C.body,
    this.border,
    this.shadows,
  });
  final UI icon;
  final VoidCallback? onTap;
  final String label;
  final double size, iconSize;
  final Color bg, fg;
  final Color? border;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        label: label,
        scale: .92,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border!),
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: UIcon(icon, size: iconSize, color: fg),
        ),
      );
}

/// iOS-style switch drawn to the Umbra palette.
class UToggle extends StatelessWidget {
  const UToggle({super.key, required this.on, required this.onTap, this.label = 'Toggle', this.springy = false});
  final bool on;
  final VoidCallback? onTap;
  final String label;
  final bool springy;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 50,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: on ? C.toggleOn : C.toggleOff, borderRadius: BorderRadius.circular(15)),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: springy ? 250 : 200),
                  curve: springy ? easeSpring : Curves.easeOut,
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: C.card,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x33000000))],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Rotating chevron for disclosure rows.
class Chevron extends StatelessWidget {
  const Chevron({super.key, required this.open, this.color = C.muted, this.size = 12, this.icon = UI.chevDown});
  final bool open;
  final Color color;
  final double size;
  final UI icon;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
        turns: open ? .5 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        child: UIcon(icon, size: size, color: color),
      );
}

/// Small glyph for a memory layer: square (identity), dot (preference),
/// ring (pattern) or dashed ring (live).
class LayerShape extends StatelessWidget {
  const LayerShape(this.layerId, {super.key, this.size = 10});
  final String layerId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final L = layerById[layerId]!;
    switch (L.shape) {
      case ShapeKind.square:
        return Container(width: size, height: size, decoration: BoxDecoration(color: L.shapeColor, borderRadius: BorderRadius.circular(3)));
      case ShapeKind.dot:
        return Container(width: size, height: size, decoration: BoxDecoration(color: L.shapeColor, shape: BoxShape.circle));
      case ShapeKind.ring:
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: L.shapeColor, width: 2)));
      case ShapeKind.dashedRing:
        return CustomPaint(size: Size.square(size), painter: DashedCirclePainter(color: L.shapeColor, width: 2, dashes: 6));
    }
  }
}

class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({required this.color, this.width = 1.5, this.dashes = 24});
  final Color color;
  final double width;
  final int dashes;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final r = Rect.fromLTWH(width / 2, width / 2, size.width - width, size.height - width);
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(r, i * step, step * .55, false, p);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) => old.color != color || old.width != width || old.dashes != dashes;
}

/// Dashed rounded-rect outline (the "coming soon" and "add" boxes).
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, this.radius = 20, this.color = C.dash, this.width = 1.5, this.padding, this.height});
  final Widget child;
  final double radius, width;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final double? height;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedRRectPainter(radius, color, width),
        child: Container(height: height, padding: padding, child: child),
      );
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter(this.radius, this.color, this.width);
  final double radius, width;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(width / 2);
    final path = Path()..addRRect(rr);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), p);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.radius != radius || old.color != color || old.width != width;
}

/// Circular progress ring (CSS conic-gradient replacement).
class Ring extends StatelessWidget {
  const Ring({super.key, required this.pct, required this.color, required this.track, required this.size, required this.thickness, this.child});
  final double pct, size, thickness;
  final Color color, track;
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: pct.clamp(0, 1)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(v, color, track, thickness),
          child: SizedBox.square(dimension: size, child: Center(child: c)),
        ),
        child: child,
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.pct, this.color, this.track, this.thickness);
  final double pct, thickness;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness, size.height - thickness);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = track);
    if (pct > 0) canvas.drawArc(r, -math.pi / 2, 2 * math.pi * pct, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct || old.color != color || old.track != track;
}

/// Segmented donut.
class Donut extends StatelessWidget {
  const Donut({super.key, required this.segments, required this.size, required this.thickness, required this.empty, this.child});
  final List<(double, Color)> segments;
  final double size, thickness;
  final Color empty;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _DonutPainter(segments, thickness, empty),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.segments, this.thickness, this.empty);
  final List<(double, Color)> segments;
  final double thickness;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness, size.height - thickness);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    final total = segments.fold<double>(0, (a, s) => a + s.$1);
    if (total <= 0) {
      canvas.drawArc(r, 0, 2 * math.pi, false, p..color = empty);
      return;
    }
    var a = -math.pi / 2;
    for (final (v, c) in segments) {
      if (v <= 0) continue;
      final sweep = 2 * math.pi * v / total;
      canvas.drawArc(r, a, sweep, false, p..color = c);
      a += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// Five confidence dots.
class ConfDots extends StatelessWidget {
  const ConfDots(this.conf, {super.key, this.size = 8, this.on = C.blue, this.off = const Color(0xFFD3DDE7), this.gap = 4});
  final double? conf;
  final double size, gap;
  final Color on, off;

  @override
  Widget build(BuildContext context) {
    final n = ((conf ?? 0) * 5).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Container(width: size, height: size, decoration: BoxDecoration(color: i < n ? on : off, shape: BoxShape.circle)),
        ]
      ],
    );
  }
}

/// Rounded square glyph tile (connected app / source code).
class GlyphTile extends StatelessWidget {
  const GlyphTile({super.key, required this.glyph, required this.bg, required this.fg, this.size = 38, this.radius = 12, this.fontSize = 15, this.ring, this.ringWidth = 2.5});
  final String glyph;
  final Color bg, fg;
  final double size, radius, fontSize, ringWidth;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: ring == null ? null : Border.all(color: ring!, width: ringWidth, strokeAlign: BorderSide.strokeAlignOutside),
        ),
        alignment: Alignment.center,
        child: Text(glyph, style: serif(fontSize, color: fg, height: 1)),
      );
}

/// Overlapping stack of tiles.
class OverlapRow extends StatelessWidget {
  const OverlapRow({super.key, required this.children, required this.overlap, required this.itemWidth, this.height});
  final List<Widget> children;
  final double overlap, itemWidth;

  /// Defaults to [itemWidth] (square tiles).
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final w = itemWidth + (children.length - 1) * (itemWidth - overlap);
    return SizedBox(
      width: w,
      height: height ?? itemWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < children.length; i++) Positioned(left: i * (itemWidth - overlap), top: 0, bottom: 0, child: Center(child: children[i])),
        ],
      ),
    );
  }
}

/// Book-like cover used across Today.
class Cover extends StatelessWidget {
  const Cover({super.key, required this.bg, required this.fg, required this.width, required this.height, this.glyph, this.child, this.radiusL = 4, this.radiusR = 10});
  final Color bg, fg;
  final double width, height, radiusL, radiusR;
  final String? glyph;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(radiusL), right: Radius.circular(radiusR)),
          boxShadow: const [BoxShadow(offset: Offset(0, 8), blurRadius: 14, spreadRadius: -10, color: Color(0x992B2620))],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(radiusL), right: Radius.circular(radiusR)),
          border: const Border(left: BorderSide(color: Color(0x1F000000), width: 3)),
        ),
        alignment: Alignment.center,
        child: child ?? (glyph == null ? null : Text(glyph!, style: serif(width * .45, color: fg, height: 1))),
      );
}

/// Staggered pop-in (the CSS `tilePop` keyframes).
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = easeSpring.transform(_c.value);
          final o = (_c.value / .6).clamp(0.0, 1.0);
          return Opacity(
            opacity: o,
            child: Transform.translate(
              offset: Offset(0, -14 * (1 - t)),
              child: Transform.rotate(angle: -4 * math.pi / 180 * (1 - t), child: Transform.scale(scale: .7 + .3 * t, child: child)),
            ),
          );
        },
      );
}

/// Bottom-sheet chrome: paper background, rounded top, grab handle.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 20), this.gap = 18, this.scroll = true});
  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Container(width: 36, height: 5, decoration: BoxDecoration(color: C.dash, borderRadius: BorderRadius.circular(3)))),
        for (final c in children) ...[SizedBox(height: gap), c],
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: (mq.size.height - mq.viewInsets.bottom) * .9),
        decoration: const BoxDecoration(color: C.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: scroll
              ? SingleChildScrollView(padding: padding, child: body)
              : Padding(padding: padding, child: body),
        ),
      ),
    );
  }
}

Future<T?> showUmbraSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: C.scrim,
      elevation: 0,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: builder,
    );

/// Borderless text input on a card background.
class UField extends StatelessWidget {
  const UField({
    super.key,
    required this.controller,
    this.hint,
    this.height = 60,
    this.fontSize = 17,
    this.serifFont = false,
    this.obscure = false,
    this.keyboard,
    this.autofill,
    this.onSubmitted,
    this.onChanged,
    this.action,
    this.bg = C.card,
    this.radius = 18,
    this.maxLines = 1,
    this.autofocus = false,
    this.capitalization = TextCapitalization.none,
  });
  final TextEditingController controller;
  final String? hint;
  final double height, fontSize, radius;
  final bool serifFont, obscure, autofocus;
  final TextInputType? keyboard;
  final Iterable<String>? autofill;
  final ValueChanged<String>? onSubmitted, onChanged;
  final TextInputAction? action;
  final Color bg;
  final int maxLines;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final style = serifFont ? serif(fontSize) : sans(fontSize);
    final multi = maxLines > 1;
    return Container(
      height: multi ? null : height,
      padding: EdgeInsets.symmetric(horizontal: multi ? 14 : 20, vertical: multi ? 12 : 0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: multi ? TextInputType.multiline : keyboard,
        autofillHints: autofill,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: action,
        autofocus: autofocus,
        minLines: multi ? maxLines : 1,
        maxLines: maxLines,
        textCapitalization: capitalization,
        style: style,
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: style.copyWith(color: C.muted)),
      ),
    );
  }
}

/// Tiny uppercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = C.muted, this.size = 11, this.spacing = .1});
  final String text;
  final Color color;
  final double size, spacing;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: caps(size, color: color, spacing: spacing));
}

/// Expands/collapses content with a size + fade animation.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.open, required this.child, this.duration = const Duration(milliseconds: 280)});
  final bool open;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: duration,
        curve: easeOutSoft,
        alignment: Alignment.topCenter,
        child: open ? child : const SizedBox(width: double.infinity),
      );
}
