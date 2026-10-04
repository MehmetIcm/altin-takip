import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/price_snapshot.dart';

/// Son başarılı fiyat verisini saklar. Okunan veri her zaman "önbellek"
/// olarak işaretlenir; canlıymış gibi sunulmaz.
class SnapshotCache {
  SnapshotCache(this._prefs);

  static const _key = 'snapshot_v1';
  final SharedPreferences _prefs;

  Future<void> save(PriceSnapshot s) async {
    await _prefs.setString(_key, jsonEncode(s.toJson()));
  }

  PriceSnapshot? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return PriceSnapshot.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
