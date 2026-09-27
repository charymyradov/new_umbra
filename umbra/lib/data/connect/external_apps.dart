/// "Continue with Umbra": the apps that may ask, what they may ask for, and
/// what they get to read.
///
/// An app opens Umbra with
///   `umbra://authorize?app=litlist&challenge=...&scopes=a,b,c&state=...`
/// and gets its answer at the callback registered below (never one taken from the link):
///   `litlist://umbra-callback?code=...&state=...` or `...?error=access_denied&state=...`
library;

import '../../domain/rules.dart';
import '../models.dart';

/// Scope → what the person is told is shared.
const kScopeCatalog = <String, String>{
  'identity.name': 'Your name',
  'identity.role': 'What you do',
  'reading.profile': 'Reading topics, times and formats',
  'memory.preferences': 'Preferences you confirmed',
  'memory.patterns': 'Patterns Umbra noticed',
  'memory.live': 'What’s going on for you right now',
};

class ExternalAppDef {
  const ExternalAppDef({
    required this.id,
    required this.name,
    required this.glyph,
    required this.callback,
    required this.allowedScopes,
    required this.purpose,
  });
  final String id, name, glyph;

  /// Where the answer goes; fixed here so a link can't redirect it.
  final String callback;

  /// The most this app may ever ask for.
  final Set<String> allowedScopes;

  /// Shown on the consent screen: "It asks [purpose]."
  final String purpose;
}

const kExternalApps = <String, ExternalAppDef>{
  'litlist': ExternalAppDef(
    id: 'litlist',
    name: 'LitList',
    glyph: 'L',
    callback: 'litlist://umbra-callback',
    allowedScopes: {'identity.name', 'identity.role', 'reading.profile', 'memory.preferences', 'memory.patterns', 'memory.live'},
    purpose: 'to set up your reading lists without asking you again',
  ),
};

/// A validated `umbra://authorize` request.
class ConnectRequest {
  const ConnectRequest({required this.app, required this.challenge, required this.scopes, required this.state});
  final ExternalAppDef app;
  final String challenge, state;
  final List<String> scopes;

  static final _challengeRe = RegExp(r'^[A-Za-z0-9_-]{43}$');
  static final _stateRe = RegExp(r'^[A-Za-z0-9_-]{8,128}$');

  /// Null when the link is not a well-formed request from a known app.
  static ConnectRequest? tryParse(Uri uri) {
    if (uri.scheme != 'umbra' || uri.host != 'authorize') return null;
    final q = uri.queryParameters;
    final app = kExternalApps[q['app']];
    final challenge = q['challenge'] ?? '', state = q['state'] ?? '';
    if (app == null || !_challengeRe.hasMatch(challenge) || !_stateRe.hasMatch(state)) return null;
    final asked = (q['scopes'] ?? '').split(',').map((s) => s.trim()).toSet();
    // Catalogue order, and only what this app is allowed to ask for.
    final scopes = [for (final s in kScopeCatalog.keys) if (asked.contains(s) && app.allowedScopes.contains(s)) s];
    if (scopes.isEmpty) return null;
    return ConnectRequest(app: app, challenge: challenge, scopes: scopes, state: state);
  }

  Uri callback(Map<String, String> params) => Uri.parse(app.callback).replace(queryParameters: {...params, 'state': state});
}

/// The single document an app may read: `users/{uid}/shared/{appId}`.
///
/// Only granted scopes are included, and never sensitive (health) memories or
/// ones from a paused source.
Map<String, Object?> buildShare(AccountData a, String appId, List<String> scopes, DateTime now) {
  final has = scopes.toSet().contains;
  final name = a.name.trim();
  final role = a.role.trim();
  final mem = [for (final m in a.mem) if (!m.sensitive && a.allowed(m.source, m.conn)) m];
  List<Memory> ofLayer(String l) => [for (final m in mem) if (m.layer == l) m];

  final profile = {
    if (has('identity.name') && name.isNotEmpty && name != 'there') ...{'name': name, 'first_name': name.split(' ').first},
    if (has('identity.role') && role.isNotEmpty) 'role': role,
  };
  final memories = {
    if (has('memory.preferences')) 'preferences': [for (final m in ofLayer('preference')) m.text],
    if (has('memory.patterns'))
      'patterns': [
        for (final m in ofLayer('pattern')) {'statement': m.text, if (m.confidence != null) 'confidence': m.confidence},
      ],
    if (has('memory.live'))
      'live': [
        for (final m in ofLayer('live'))
          if (expiresAt(m).isAfter(now)) {'statement': m.text, 'expires_at': expiresAt(m).toUtc().toIso8601String()},
      ],
  };
  return {
    'version': 1,
    'app_id': appId,
    'scopes': scopes,
    if (profile.isNotEmpty) 'profile': profile,
    if (has('reading.profile')) 'reading': {'topics': a.topics, 'goals': const <String>[], 'times': a.times, 'formats': a.formats},
    if (memories.isNotEmpty) 'memories': memories,
  };
}
