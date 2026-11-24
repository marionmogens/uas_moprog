import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';

// Lapisan penyimpanan lokal (Data Persistence, Pertemuan 10).
// Memakai SharedPreferences: menyimpan sesi login + salinan profil
// sebagai teks JSON, jadi tetap ada setelah aplikasi ditutup.
//
// Catatan: SharedPreferences tidak terenkripsi. Cukup untuk tugas ini;
// untuk aplikasi produksi, token sebaiknya disimpan di
// flutter_secure_storage.
class SessionStorage {
  static const String _sessionKey = 'auth_session';
  static const String _profileKey = 'auth_profile';

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // data rusak -> anggap belum login
    }
  }

  Future<void> saveProfile(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(user.toJson()));
  }

  Future<AppUser?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_profileKey);
  }
}