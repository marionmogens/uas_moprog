import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament.dart';

// Menyimpan turnamen di HP, terpisah per akun (seperti FavoriteStore).
class TournamentStore {
  TournamentStore._();

  static String _key(String userId) => 'tournaments_$userId';

  static Future<List<Tournament>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(String userId, List<Tournament> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(userId), jsonEncode(all.map((t) => t.toJson()).toList()));
  }

  // Tambah baru (di paling atas) atau perbarui yang sudah ada.
  static Future<void> upsert(String userId, Tournament t) async {
    final all = await load(userId);
    final i = all.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      all[i] = t;
    } else {
      all.insert(0, t);
    }
    await _saveAll(userId, all);
  }

  static Future<void> delete(String userId, String id) async {
    final all = await load(userId);
    all.removeWhere((t) => t.id == id);
    await _saveAll(userId, all);
  }
}