import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'data/backend.dart';
import 'data/connect/auth_worker.dart';
import 'data/firebase/firebase_auth_gateway.dart';
import 'data/firebase/firestore_account_store.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'firebase_options.dart';
import 'state/connect_controller.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/fonts, so never hit the network for them.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Warm every bundled face up front so no screen flashes a fallback font.
  for (final w in const [FontWeight.w400, FontWeight.w500, FontWeight.w600]) {
    sans(12, weight: w);
    fredoka(12, weight: w);
  }
  serif(12);
  serif(12, italic: true);
  final (prefs, backend, _) = await (SharedPreferences.getInstance(), _firebase(), GoogleFonts.pendingFonts()).wait;
  final mobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      backendProvider.overrideWithValue(backend ?? Backend(auth: AuthRepository(prefs), store: AccountRepository(prefs))),
      if (mobile) incomingLinksProvider.overrideWithValue(_links()),
    ],
    child: const UmbraApp(),
  ));
}

/// Firebase accounts on Android, iOS and the web; null where the project has no
/// Firebase app configured (desktop), which then keeps accounts on the device.
Future<Backend?> _firebase() async {
  if (!kIsWeb && !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) return null;
  try {
    final app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final auth = FirebaseAuthGateway(FirebaseAuth.instanceFor(app: app));
    await auth.restore();
    return Backend(
      auth: auth,
      store: FirestoreAccountStore(FirebaseFirestore.instanceFor(app: app, databaseId: firestoreDatabaseId)),
      worker: AuthWorker(authWorkerUrl),
    );
  } catch (e) {
    debugPrint('Umbra: Firebase unavailable, using local accounts: $e');
    return null;
  }
}

/// `umbra://authorize` links: the one that launched the app, then any later ones.
Stream<Uri> _links() async* {
  final links = AppLinks();
  final first = await links.getInitialLink();
  if (first != null) yield first;
  yield* links.uriLinkStream;
}
