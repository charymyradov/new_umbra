import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/icons.dart';
import 'auth_view_model.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

/// Text controllers are view concerns; mode, validation and errors live in [AuthViewModel].
class _AuthViewState extends ConsumerState<AuthView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  AuthViewModel get _vm => ref.read(authViewModelProvider.notifier);

  void _submit() => _vm.submit(name: _name.text, email: _email.text, password: _pw.text);

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: C.paper,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: easeOutSoft,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a), child: c),
            ),
            child: st.mode == AuthMode.welcome ? _welcome() : _form(st),
          ),
        ),
      ),
    );
  }

  Widget _welcome() => Column(
        key: const ValueKey('welcome'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 72),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const UmbraMark(),
                const SizedBox(height: 36),
                Text('Umbra', style: serif(44, height: 1)),
                const SizedBox(height: 14),
                Text('A portable memory of you, that you can see and control.', style: serif(22, italic: true, color: C.body, height: 1.3)),
              ]),
            ),
          ),
          PillButton(label: 'Create account', height: 58, fontSize: 16, onTap: () => _vm.go(AuthMode.signup)),
          const SizedBox(height: 10),
          PillButton(label: 'Sign in', height: 58, fontSize: 16, bg: C.card, fg: C.ink, weight: FontWeight.w400, onTap: () => _vm.go(AuthMode.signin)),
          const SizedBox(height: 4),
          TextLink('Explore the demo account', onTap: _vm.tryDemo),
        ],
      );

  Widget _form(AuthState st) {
    final signup = st.isSignup;
    return Column(
      key: ValueKey(st.mode),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RoundIconButton(icon: UI.back, label: 'Back', size: 36, iconSize: 14, fg: C.ink, border: C.line, onTap: () => _vm.go(AuthMode.welcome)),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 28, bottom: 16),
            child: AutofillGroup(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(st.title, style: serif(34, height: 1.1)),
                const SizedBox(height: 8),
                Text(st.subtitle, style: sans(15, color: C.body)),
                const SizedBox(height: 28),
                if (signup) ...[
                  UField(
                    controller: _name,
                    hint: 'Name',
                    autofill: const [AutofillHints.name],
                    action: TextInputAction.next,
                    capitalization: TextCapitalization.words,
                    onChanged: (_) => _clearErr(),
                  ),
                  const SizedBox(height: 12),
                ],
                UField(
                  controller: _email,
                  hint: 'Email',
                  keyboard: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  action: TextInputAction.next,
                  onChanged: (_) => _clearErr(),
                ),
                const SizedBox(height: 12),
                UField(
                  controller: _pw,
                  hint: 'Password',
                  obscure: true,
                  autofill: [signup ? AutofillHints.newPassword : AutofillHints.password],
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => _clearErr(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: st.error.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
                          child: Row(children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(st.error, style: sans(13, color: C.red))),
                          ]),
                        ),
                ),
              ]),
            ),
          ),
        ),
        PillButton(label: st.submitLabel, height: 58, fontSize: 16, enabled: !st.busy, onTap: _submit),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(st.switchPrompt, style: sans(14, color: C.muted)),
          const SizedBox(width: 6),
          TextLink(st.switchLabel, color: C.ink, weight: FontWeight.w500, onTap: _vm.switchMode),
        ]),
      ],
    );
  }

  void _clearErr() => _vm.clearError();
}

/// The eclipse mark: an ink disc partly covered by a paper disc.
class UmbraMark extends StatelessWidget {
  const UmbraMark({super.key, this.size = 132, this.outlined = false});
  final double size;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle)),
          Positioned(
            left: size * 30 / 132,
            top: -size * 12 / 132,
            width: size,
            height: size,
            child: Container(
              decoration: BoxDecoration(
                color: C.paper,
                shape: BoxShape.circle,
                border: outlined ? Border.all(color: C.line) : null,
              ),
            ),
          ),
        ]),
      );
}
