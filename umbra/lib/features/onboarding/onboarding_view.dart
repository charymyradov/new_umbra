import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import '../privacy/mech_row.dart';
import '../privacy/permissions_view_model.dart';
import 'onboarding_view_model.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  late final _name = TextEditingController(text: ref.read(onboardingViewModelProvider).name);
  late final _role = TextEditingController(text: ref.read(onboardingViewModelProvider).role);

  OnboardingViewModel get _vm => ref.read(onboardingViewModelProvider.notifier);

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(onboardingViewModelProvider);
    return Scaffold(
      backgroundColor: C.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 44,
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: s.canBack
                      ? Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: RoundIconButton(
                              icon: UI.back,
                              label: 'Back',
                              size: 36,
                              iconSize: 14,
                              fg: C.ink,
                              border: C.line,
                              onTap: _vm.back),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Row(children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 3,
                          decoration: BoxDecoration(color: i <= s.step ? C.ink : C.line, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ]
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: easeOutSoft,
                layoutBuilder: (cur, prev) => Stack(fit: StackFit.expand, children: [...prev, ?cur]),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: Offset(.08 * s.dir, 0), end: Offset.zero).animate(a), child: c),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(s.step),
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: switch (s.step) {
                    1 => _who(),
                    2 => _domains(s),
                    _ => const _Mechs(),
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            PillButton(
              label: s.nextLabel,
              height: 58,
              fontSize: 16,
              onTap: () {
                FocusScope.of(context).unfocus();
                _vm.next();
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _who() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('First, who are you?', style: serif(34, height: 1.1)),
        const SizedBox(height: 28),
        UField(controller: _name, hint: 'Name', fontSize: 18, onChanged: _vm.setName, action: TextInputAction.next, capitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        UField(controller: _role, hint: 'What you do', fontSize: 18, onChanged: _vm.setRole, action: TextInputAction.done, capitalization: TextCapitalization.sentences),
        const SizedBox(height: 28),
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Text('Saved to Identity', style: sans(13, color: C.body)),
        ]),
      ]);

  Widget _domains(OnboardingState s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Which parts of you?', style: serif(34, height: 1.1)),
        const SizedBox(height: 10),
        Text('Start with a few. Each gets a one-minute quiz. No apps needed.', style: sans(15, color: C.body, height: 1.45)),
        const SizedBox(height: 22),
        for (final d in domains) ...[
          _DomainPick(d: d, on: s.chosenDomains.contains(d.id), onTap: () => _vm.toggleDomain(d.id)),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Padding(padding: const EdgeInsets.only(right: 4), child: Text('Coming next', style: sans(12, color: C.muted))),
          for (final n in soonDomains)
            DashedBox(
              radius: 14,
              width: 1,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(widthFactor: 1, child: Text(n, style: sans(12, color: C.muted))),
            ),
        ]),
      ]);
}

class _Mechs extends ConsumerWidget {
  const _Mechs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(permissionsViewModelProvider);
    final vm = ref.read(permissionsViewModelProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('How may I learn?', style: serif(34, height: 1.1)),
      const SizedBox(height: 10),
      Text('Anything I notice waits for your OK.', style: sans(15, color: C.body, height: 1.45)),
      const SizedBox(height: 22),
      for (final r in rows) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          constraints: const BoxConstraints(minHeight: 62),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
          child: MechRow(row: r, compact: false, onToggle: () => vm.toggle(r.key)),
        ),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

class _DomainPick extends StatelessWidget {
  const _DomainPick({required this.d, required this.on, required this.onTap});
  final Domain d;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        label: d.name,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: on ? 1 : .55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: d.bg, borderRadius: BorderRadius.circular(22), border: Border.all(color: on ? d.color : Colors.transparent, width: 2)),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: d.color, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.center,
                child: UIcon(UI.forDomain(d.id), size: 22, color: C.card),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: serif(21, color: d.color)),
                  const SizedBox(height: 2),
                  Text(d.blurb, style: sans(12, color: C.body)),
                ]),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: on ? d.color : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: d.color, width: 1.5)),
                alignment: Alignment.center,
                child: const UIcon(UI.check, size: 12, color: C.card),
              ),
            ]),
          ),
        ),
      );
}
