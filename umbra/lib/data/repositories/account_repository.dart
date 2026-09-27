import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend.dart';
import '../catalog.dart';
import '../models.dart';

/// Keeps one account's [AccountData] as a JSON string in [SharedPreferences].
///
/// Used for the demo account and wherever Firebase isn't available.
class AccountRepository implements AccountStore {
  AccountRepository(this._prefs);

  static const _kDataPrefix = 'umbra.data.v3.';
  final SharedPreferences _prefs;

  @override
  Future<AccountData?> load(String uid) async => peek(uid);

  @override
  AccountData? peek(String uid) {
    final raw = _prefs.getString('$_kDataPrefix$uid');
    if (raw == null) return null;
    try {
      return AccountData.fromJson(jsonDecode(raw) as Map<String, Object?>, defaultConns: defaultConns);
    } catch (e) {
      debugPrint('Umbra: could not restore data for $uid: $e');
      return null;
    }
  }

  @override
  Future<void> save(String uid, AccountData data) => _prefs.setString('$_kDataPrefix$uid', jsonEncode(data.toJson()));
}
