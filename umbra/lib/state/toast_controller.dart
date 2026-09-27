import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Toast {
  const Toast(this.id, this.msg, this.onUndo);
  final int id;
  final String msg;
  final VoidCallback? onUndo;
}

/// One toast at a time; undoable toasts stay a little longer.
class ToastController extends Notifier<Toast?> {
  Timer? _timer;
  int _seq = 0;

  @override
  Toast? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(String msg, {VoidCallback? onUndo}) {
    _timer?.cancel();
    state = Toast(++_seq, msg, onUndo);
    _timer = Timer(Duration(milliseconds: onUndo != null ? 6000 : 2800), dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }

  void undo() {
    final u = state?.onUndo;
    dismiss();
    u?.call();
  }
}

final toastProvider = NotifierProvider<ToastController, Toast?>(ToastController.new);
