import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/session_controller.dart';

enum AuthMode { welcome, signin, signup }

class AuthState {
  const AuthState({this.mode = AuthMode.welcome, this.error = '', this.busy = false});
  final AuthMode mode;
  final String error;

  /// Waiting for the account server.
  final bool busy;

  bool get isSignup => mode == AuthMode.signup;
  String get title => isSignup ? 'Create your account' : 'Welcome back';
  String get subtitle => isSignup ? 'Your memory stays tied to you.' : 'Pick up where you left off.';
  String get submitLabel => busy ? (isSignup ? 'Creating…' : 'Signing in…') : (isSignup ? 'Create account' : 'Sign in');
  String get switchPrompt => isSignup ? 'Have an account?' : 'New here?';
  String get switchLabel => isSignup ? 'Sign in' : 'Create account';
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void go(AuthMode mode) => state = AuthState(mode: mode);

  void switchMode() => go(state.isSignup ? AuthMode.signin : AuthMode.signup);

  void clearError() {
    if (state.error.isNotEmpty) state = AuthState(mode: state.mode);
  }

  Future<void> submit({required String name, required String email, required String password}) async {
    if (state.busy) return;
    final mode = state.mode;
    state = AuthState(mode: mode, busy: true);
    final session = ref.read(sessionProvider.notifier);
    final err = mode == AuthMode.signup ? await session.signUp(name: name, email: email, password: password) : await session.signIn(email: email, password: password);
    if (ref.mounted) state = AuthState(mode: mode, error: err ?? '');
  }

  void tryDemo() => ref.read(sessionProvider.notifier).tryDemo();
}

final authViewModelProvider = NotifierProvider.autoDispose<AuthViewModel, AuthState>(AuthViewModel.new);
