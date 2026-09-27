import 'package:flutter/material.dart';

import '../data/catalog.dart';
import 'icons.dart';

/// Round domain icon badge.
class DomainBadge extends StatelessWidget {
  const DomainBadge(this.dom, {super.key, this.size = 32, this.iconSize = 15, this.bg, this.fg});
  final String dom;
  final double size, iconSize;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    final d = domainById[dom] ?? coreDomain;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg ?? d.bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: UIcon(UI.forDomain(dom), size: iconSize, color: fg ?? d.color),
    );
  }
}
