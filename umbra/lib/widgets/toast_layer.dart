import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import '../state/toast_controller.dart';
import 'common.dart';

/// Floating toast with optional Undo. Sits above every route (including sheets).
class ToastLayer extends ConsumerWidget {
  const ToastLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(toastProvider);
    final toast = ref.read(toastProvider.notifier);
    final inApp = ref.watch(screenProvider) == Screen.app;
    final bottom = MediaQuery.of(context).padding.bottom + (inApp ? 100 : 24);
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: easeOutSoft,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a), child: child),
          ),
          child: t == null
              ? const SizedBox.shrink()
              : Material(
                  key: ValueKey(t.id),
                  type: MaterialType.transparency,
                  child: GestureDetector(
                    onVerticalDragEnd: (_) => toast.dismiss(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: C.ink,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [BoxShadow(offset: Offset(0, 14), blurRadius: 30, spreadRadius: -12, color: Color(0x73000000))],
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(t.msg, style: sans(14, color: C.paper, height: 1.4)),
                          ),
                        ),
                        if (t.onUndo != null)
                          PillButton(label: 'Undo', onTap: toast.undo, height: 40, bg: C.inkLine, fg: C.paper, fontSize: 14, weight: FontWeight.w400, expand: false, padding: 16),
                        if (t.onUndo == null) const SizedBox(width: 12),
                      ]),
                    ),
                  ),
                ),
      ),
    );
  }
}
