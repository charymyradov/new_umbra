import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'permissions_view_model.dart';

/// A learning-permission row (a–e). The compact (Privacy) variant adds a "Forget N" link.
class MechRow extends StatelessWidget {
  const MechRow({super.key, required this.row, required this.compact, required this.onToggle, this.onForget});
  final MechRowState row;
  final bool compact;
  final VoidCallback onToggle;
  final VoidCallback? onForget;

  @override
  Widget build(BuildContext context) {
    final tile = compact ? 34.0 : 38.0;
    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: tile,
        height: tile,
        decoration: BoxDecoration(color: row.on ? row.def.color : const Color(0xFFCFC5B4), borderRadius: BorderRadius.circular(compact ? 11 : 12)),
        alignment: Alignment.center,
        child: Text(row.def.code, style: serif(compact ? 16 : 18, color: C.card, height: 1)),
      ),
      SizedBox(width: compact ? 12 : 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(row.def.name, style: sans(compact ? 14 : 15, weight: FontWeight.w500)),
          const SizedBox(height: 2),
          if (!compact)
            Text(row.def.short, style: sans(12, color: C.muted))
          else
            Row(children: [
              Text(row.rule, style: sans(12, color: row.locked || row.on ? C.body : C.muted)),
              if (row.count > 0 && onForget != null) ...[
                Text('  ·  ', style: sans(12, color: C.muted)),
                GestureDetector(onTap: onForget, child: Text('Forget ${row.count}', style: sans(12, color: C.red))),
              ],
            ]),
        ]),
      ),
      if (row.locked)
        Padding(padding: const EdgeInsets.only(right: 4), child: Text('Always on', style: sans(12, color: C.muted)))
      else
        UToggle(on: row.on, label: row.def.name, onTap: onToggle),
    ]);
  }
}
