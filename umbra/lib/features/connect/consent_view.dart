import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../auth/auth_view.dart';
import 'consent_view_model.dart';

/// "LitList wants to use your Umbra account" — Allow / Cancel.
class ConsentView extends ConsumerWidget {
  const ConsentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(consentViewModelProvider);
    final vm = ref.read(consentViewModelProvider.notifier);
    if (st == null) return const Scaffold(backgroundColor: C.paper);
    return Scaffold(
      backgroundColor: C.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 48, bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GlyphTile(glyph: st.app.glyph, bg: C.ink, fg: C.paper, size: 56, radius: 18, fontSize: 22),
                    const SizedBox(width: 14),
                    const UIcon(UI.swap, size: 18, color: C.faint),
                    const SizedBox(width: 14),
                    const UmbraMark(size: 44, outlined: true),
                  ]),
                  const SizedBox(height: 28),
                  Text('${st.app.name} wants to use your Umbra account', style: serif(30, height: 1.1)),
                  const SizedBox(height: 10),
                  Text('It asks ${st.app.purpose}.', style: sans(15, color: C.body, height: 1.4)),
                  const SizedBox(height: 26),
                  const SectionLabel('IT WILL SEE'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(22)),
                    child: Column(children: [
                      for (final s in st.scopes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(children: [
                            const UIcon(UI.check, size: 14, color: C.green, stroke: 3),
                            const SizedBox(width: 12),
                            Expanded(child: Text(s, style: sans(15, height: 1.3))),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(padding: EdgeInsets.only(top: 2), child: UIcon(UI.lock, size: 13, color: C.muted)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Health stays private. It never sees your password or anything else. Disconnect any time in Privacy → Connected apps.',
                        style: sans(13, color: C.muted, height: 1.4),
                      ),
                    ),
                  ]),
                  if (st.error != null) ...[
                    const SizedBox(height: 16),
                    Text(st.error!, style: sans(13, color: C.red)),
                  ],
                ]),
              ),
            ),
            if (st.email.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Signed in as ${st.email}', textAlign: TextAlign.center, style: sans(13, color: C.muted))),
            PillButton(label: st.busy ? 'Connecting…' : 'Allow', height: 58, fontSize: 16, enabled: !st.busy, onTap: vm.allow),
            const SizedBox(height: 6),
            TextLink('Cancel', onTap: st.busy ? null : vm.deny),
          ]),
        ),
      ),
    );
  }
}
