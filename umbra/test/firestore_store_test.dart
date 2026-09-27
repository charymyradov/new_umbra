import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umbra/data/backend.dart';
import 'package:umbra/data/catalog.dart';
import 'package:umbra/data/connect/auth_worker.dart';
import 'package:umbra/data/connect/external_apps.dart';
import 'package:umbra/data/firebase/firestore_account_store.dart';
import 'package:umbra/data/models.dart';
import 'package:umbra/domain/rules.dart';
import 'package:umbra/state/account_controller.dart';
import 'package:umbra/state/connect_controller.dart';
import 'package:umbra/state/providers.dart';
import 'package:umbra/state/session_controller.dart';

const uid = 'u1';
final t0 = DateTime.utc(2026, 9, 24, 9, 41);

Memory mem(String id, {String layer = 'preference', String? conn, String source = 'explicit', bool sensitive = false}) =>
    Memory(id: id, layer: layer, text: 'Memory $id', source: source, conn: conn, sensitive: sensitive, detail: 'test', steps: const ['a'], created: t0, confirmed: t0);

const pend = Pending(id: 'p1', source: 'behavioral', prompt: 'You read at night', layer: 'pattern', text: 'Reads at night', memId: 'pt_night', conf: .4);

AccountData account() => AccountData(
      onboarded: true,
      name: 'Ada Lovelace',
      role: 'Engineer',
      topics: const ['Design'],
      times: const ['Evening'],
      formats: const ['print'],
      connsOn: defaultConns,
      mem: [mem('a'), mem('k', source: 'crossapp', conn: 'kindle'), mem('h', sensitive: true), mem('l', layer: 'pattern')],
      pending: const [pend],
      log: [LogEntry(t0, 'Hello')],
      linked: {'litlist': LinkedApp(scopes: const ['identity.name', 'reading.profile', 'memory.preferences', 'memory.patterns'], since: t0)},
    );

void main() {
  late FakeFirebaseFirestore db;
  var now = t0;
  FirestoreAccountStore store() => FirestoreAccountStore(db, clock: () => now);
  Future<Map<String, dynamic>?> doc(String path) async => (await db.doc(path).get()).data();

  setUp(() {
    db = FakeFirebaseFirestore();
    now = t0;
  });

  test('writes the account in the layout LitList and the rules expect', () async {
    final s = store();
    expect(await s.load(uid), isNull);
    await s.save(uid, account());

    final user = (await doc('users/$uid'))!;
    expect(user['full_name'], 'Ada Lovelace');
    expect(user['reading'], {'topics': ['Design'], 'times': ['Evening'], 'formats': ['print']});
    expect((user['umbra'] as Map)['onboarded'], isTrue);
    expect(user['created_at'], isNotNull);

    final k = (await doc('memories/${uid}_k'))!;
    expect(k['statement'], 'Memory k');
    expect(k['user_id'], uid);
    expect((await doc('app_grants/${uid}_kindle'))!['allowed_memory_ids'], ['${uid}_k']);
    expect(await doc('app_grants/${uid}_libby'), isNull, reason: 'off by default and never on');

    final grant = (await doc('app_grants/${uid}_litlist'))!;
    expect(grant['kind'], 'external_app');
    expect(grant['duration'], 'linked');

    final share = (await doc('users/$uid/shared/litlist'))!;
    expect(share['profile'], {'name': 'Ada Lovelace', 'first_name': 'Ada'});
    expect((share['reading'] as Map)['topics'], ['Design']);
    expect((share['memories'] as Map)['preferences'], ['Memory a', 'Memory k'], reason: 'sensitive memory h is never shared');
    expect(share.containsKey('role'), isFalse);

    final events = (await db.collection('events').where('user_id', isEqualTo: uid).get()).docs.map((d) => d.data()).toList();
    expect(events.where((e) => e['kind'] == 'log').single['payload'], {'text': 'Hello'});
    expect(events.where((e) => e['kind'] == 'proposal').single['payload']['statement'], 'Reads at night');
  });

  test('reloading gives the same account back, and an unchanged save writes nothing', () async {
    await store().save(uid, account());

    final s = store();
    final a = (await s.load(uid))!;
    expect(a.name, 'Ada Lovelace');
    expect(a.mem.map((m) => m.id), ['a', 'k', 'h', 'l']);
    expect(a.pending.single.memId, 'pt_night');
    expect(a.linked.keys, ['litlist']);
    expect(a.log.single.text, 'Hello');
    expect(a.connsOn['kindle'], isTrue);

    final before = (await doc('users/$uid'))!['updated_at'];
    now = t0.add(const Duration(hours: 1));
    await s.save(uid, a);
    expect((await doc('users/$uid'))!['updated_at'], before);
  });

  test('forget, keep, pause and disconnect each land as one consistent write', () async {
    final s = store();
    await s.load(uid);
    final a = account();
    await s.save(uid, a);

    now = t0.add(const Duration(minutes: 5));
    final kept = mem('pt_night', layer: 'pattern', source: 'behavioral');
    await s.save(
      uid,
      a.copyWith(
        mem: [...a.mem.where((m) => m.id != 'k'), kept],
        pending: const [],
        connsOn: {...a.connsOn, 'podcasts': false},
        linked: const {},
        log: [LogEntry(now, 'Bye'), ...a.log],
      ),
    );

    expect(await doc('memories/${uid}_k'), isNull);
    expect(await doc('memories/${uid}_pt_night'), isNotNull);
    expect((await doc('app_grants/${uid}_kindle'))!['allowed_memory_ids'], isEmpty);
    expect((await doc('app_grants/${uid}_podcasts'))!['duration'], 'revoked');
    expect(await doc('users/$uid/shared/litlist'), isNull, reason: 'LitList loses access at once');
    expect((await doc('app_grants/${uid}_litlist'))!['duration'], 'revoked');
    expect((await doc('events/${uid}_p_p1_r'))!['payload'], {'proposal_id': '${uid}_p_p1', 'action': 'keep'});

    final back = (await store().load(uid))!;
    expect(back.pending, isEmpty);
    expect(back.linked, isEmpty);
    expect(back.connsOn['podcasts'], isFalse);
    expect(back.log.map((l) => l.text), ['Bye', 'Hello']);
  });

  test('a proposal LitList left shows up in "Is this you?"', () async {
    final s = store();
    await s.load(uid);
    await s.save(uid, account());
    await db.collection('events').add({
      'user_id': uid,
      'app_id': 'litlist',
      'kind': 'proposal',
      'payload': {'layer': 'pattern', 'statement': 'Finishes short books', 'prompt': 'From LitList', 'source': 'crossapp', 'connection': 'litlist'},
      'created_at': t0.toIso8601String(),
    });
    final a = (await store().load(uid))!;
    final p = a.pending.firstWhere((p) => p.conn == 'litlist');
    expect(a.allowed(p.source, p.conn), isTrue);
  });

  test('Allow on the consent screen links the app and returns the code', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = store();
    Map<String, Object?>? approved;
    final worker = AuthWorker('https://worker.test', client: MockClient((req) async {
      approved = jsonDecode(req.body) as Map<String, Object?>;
      expect(req.headers['authorization'], 'Bearer id-token');
      return http.Response(jsonEncode({'code': 'one-time'}), 200);
    }));
    final opened = <Uri>[];
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      backendProvider.overrideWithValue(Backend(auth: _FakeAuth(), store: s, worker: worker)),
      openUrlProvider.overrideWithValue((u) async => opened.add(u)),
    ]);
    addTearDown(c.dispose);

    c.listen(screenProvider, (_, _) {});
    await pumpEventQueue();
    expect(c.read(sessionProvider).user?.uid, uid);
    final account = c.read(accountProvider.notifier);
    account.obNext();
    account.obNext();
    account.obNext();
    expect(c.read(screenProvider), Screen.app);

    final challenge = 'A' * 43;
    c.read(connectProvider.notifier).handle(Uri.parse('umbra://authorize?app=litlist&challenge=$challenge&scopes=identity.name,reading.profile,evil.scope&state=state1234'));
    expect(c.read(screenProvider), Screen.connect);
    await c.read(connectProvider.notifier).allow();

    expect(approved, {'app': 'litlist', 'challenge': challenge, 'scopes': ['identity.name', 'reading.profile']});
    expect(opened.single.toString(), 'litlist://umbra-callback?code=one-time&state=state1234');
    expect(c.read(screenProvider), Screen.app);
    expect(await doc('users/$uid/shared/litlist'), isNotNull);
    expect(c.read(accountProvider).log.first.text, 'LitList connected with your Umbra account.');
  });

  test('links from unknown apps or without a proper challenge are ignored', () {
    expect(ConnectRequest.tryParse(Uri.parse('umbra://authorize?app=other&challenge=${'A' * 43}&scopes=identity.name&state=state1234')), isNull);
    expect(ConnectRequest.tryParse(Uri.parse('umbra://authorize?app=litlist&challenge=short&scopes=identity.name&state=state1234')), isNull);
    expect(ConnectRequest.tryParse(Uri.parse('umbra://authorize?app=litlist&challenge=${'A' * 43}&scopes=evil&state=state1234')), isNull);
  });
}

class _FakeAuth implements AuthGateway {
  @override
  AuthUser? get current => const AuthUser(uid: uid, email: 'ada@example.com', name: 'Ada');
  @override
  Future<String?> idToken() async => 'id-token';
  @override
  Future<AuthUser> signIn({required String email, required String password}) async => current!;
  @override
  Future<AuthUser> signUp({required String name, required String email, required String password}) async => current!;
  @override
  Future<void> signOut() async {}
}
