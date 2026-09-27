import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/connect/auth_worker.dart';
import '../data/connect/external_apps.dart';
import 'account_controller.dart';
import 'providers.dart';
import 'session_controller.dart';
import 'toast_controller.dart';

/// Incoming `umbra://` links. Null where there are none (web, tests); set in `main()`.
final incomingLinksProvider = Provider<Stream<Uri>?>((_) => null);

/// Opens the connected app with the answer. Replaced in tests.
final openUrlProvider = Provider<Future<void> Function(Uri)>((_) => (uri) async {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // The app was uninstalled meanwhile; nothing to answer.
      }
    });

class ConnectState {
  const ConnectState({this.request, this.busy = false, this.error});

  /// The request waiting for Allow / Cancel.
  final ConnectRequest? request;
  final bool busy;
  final String? error;
}

/// "Continue with Umbra": catches `umbra://authorize` links and answers them.
///
/// A request waits until the person is signed in and set up; the consent screen
/// shows it then (see [screenProvider]).
class ConnectController extends Notifier<ConnectState> {
  final _seen = <String>{};

  @override
  ConnectState build() {
    final sub = ref.read(incomingLinksProvider)?.listen(handle, onError: (Object _) {});
    ref.onDispose(() => sub?.cancel());
    return const ConnectState();
  }

  void handle(Uri uri) {
    final r = ConnectRequest.tryParse(uri);
    // The same link can arrive both as the launch link and on the stream.
    if (r == null || !_seen.add(r.challenge)) return;
    state = ConnectState(request: r);
  }

  /// Allow: get a one-time code for the app, save the grant and what it may read
  /// in one write, then hand the code back to the app.
  Future<void> allow() async {
    final r = state.request;
    if (r == null || state.busy) return;
    final backend = ref.read(backendProvider);
    final worker = backend.worker;
    final user = ref.read(sessionProvider).user;
    if (worker == null || user == null || user.demo) {
      state = ConnectState(request: r, error: 'Sign in with your Umbra account to connect apps.');
      return;
    }
    state = ConnectState(request: r, busy: true);
    try {
      final token = await backend.auth.idToken();
      if (token == null) throw const ConnectFailure('Please sign in again.');
      final code = await worker.approve(idToken: token, appId: r.app.id, challenge: r.challenge, scopes: r.scopes);
      final account = ref.read(accountProvider.notifier)..linkApp(r.app, r.scopes);
      final saved = await account.flush().timeout(const Duration(seconds: 15), onTimeout: () => false);
      // Without the share document the app would sign in to nothing.
      if (!saved) throw const ConnectFailure('Couldn’t save the connection. Try again.');
      state = const ConnectState();
      await ref.read(openUrlProvider)(r.callback({'code': code}));
      ref.read(toastProvider.notifier).show('${r.app.name} is connected');
    } on ConnectFailure catch (e) {
      if (ref.mounted) state = ConnectState(request: r, error: e.message);
    }
  }

  Future<void> deny() async {
    final r = state.request;
    if (r == null || state.busy) return;
    state = const ConnectState();
    await ref.read(openUrlProvider)(r.callback({'error': 'access_denied'}));
  }
}

final connectProvider = NotifierProvider<ConnectController, ConnectState>(ConnectController.new);
