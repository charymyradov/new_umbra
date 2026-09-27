import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import 'account_sheet_view_model.dart';

Future<void> openAccountSheet(BuildContext context) => showUmbraSheet(context, (_) => const AccountSheet());

class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(accountSheetViewModelProvider);
    final vm = ref.read(accountSheetViewModelProvider.notifier);
    final name = s.displayName;
    return SheetFrame(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(name[0].toUpperCase(), style: serif(28, color: C.paper, height: 1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: serif(24, height: 1.1)),
              const SizedBox(height: 3),
              Text(s.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(13, color: C.muted)),
            ]),
          ),
        ]),
      ),
      Row(children: [
        Expanded(child: _statTile('${s.memories}', 'Memories')),
        const SizedBox(width: 10),
        Expanded(child: _statTile('${s.liveSources}', 'Sources on')),
      ]),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: C.greenBg, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const UIcon(UI.check, size: 18, color: C.green, stroke: 1.8),
          const SizedBox(width: 12),
          Expanded(child: Text('Auto-saved on this device. Restored whenever you sign in.', style: sans(13, color: C.green, height: 1.4))),
        ]),
      ),
      PillButton(
        label: 'Sign out',
        bg: C.redBg,
        fg: C.red,
        onTap: () {
          Navigator.pop(context);
          vm.signOut();
        },
      ),
    ]);
  }

  Widget _statTile(String v, String k) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: serif(28, height: 1)),
          const SizedBox(height: 4),
          Text(k, style: sans(12, color: C.muted)),
        ]),
      );
}

