import 'dart:convert';

import 'package:http/http.dart' as http;

class ConnectFailure implements Exception {
  const ConnectFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Client for the Cloudflare Worker that turns the person's approval into a
/// one-time code (60 s) the connected app exchanges for its own sign-in.
class AuthWorker {
  AuthWorker(this.baseUrl, {http.Client? client}) : _http = client ?? http.Client();
  final String baseUrl;
  final http.Client _http;

  /// Throws [ConnectFailure].
  Future<String> approve({required String idToken, required String appId, required String challenge, required List<String> scopes}) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('$baseUrl/approve'),
            headers: {'content-type': 'application/json', 'authorization': 'Bearer $idToken'},
            body: jsonEncode({'app': appId, 'challenge': challenge, 'scopes': scopes}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ConnectFailure('Couldn’t reach Umbra. Check your connection.');
    }
    Object? body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {}
    final code = body is Map ? body['code'] : null;
    if (res.statusCode != 200 || code is! String) {
      throw ConnectFailure('Umbra couldn’t approve this (${body is Map ? body['error'] : res.statusCode}).');
    }
    return code;
  }
}
