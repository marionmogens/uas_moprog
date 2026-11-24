import 'package:shared_preferences/shared_preferences.dart';

// Menyimpan id tempat yang ditandai favorit di HP (SharedPreferences),
// terpisah per akun, supaya favorit tetap ada setelah aplikasi ditutup dan
// tidak tercampur kalau beberapa akun memakai HP yang sama.
class FavoriteStore {
  FavoriteStore._();

  static String _key(String userId) => 'favorite_ids_$userId';

  static Future<Set<String>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(userId)) ?? <String>[]).toSet();
  }

  static Future<void> save(String userId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), ids.toList());
  }
}