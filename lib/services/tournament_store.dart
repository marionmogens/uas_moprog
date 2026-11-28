import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/tournament.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';

// Turnamen disimpan di Supabase (tabel `tournaments`) supaya ikut akun dan
// bisa dibuka dari perangkat lain.
//
// Salinan lokal (SharedPreferences) tetap dipakai sebagai cache, jadi aplikasi
// tetap bisa dipakai saat offline:
//  - upsert/delete langsung tersimpan di cache, lalu dikirim ke server di
//    belakang layar. Kalau gagal (offline), ditandai "pending" dan dicoba lagi
//    otomatis pada load/upsert berikutnya.
//  - load menarik data terbaru dari server dan menggabungkannya dengan cache.
//    Perubahan lokal yang belum terkirim tidak tertimpa data server.
//  - Turnamen lama yang hanya ada di HP otomatis diunggah saat pertama kali
//    berhasil terhubung ke server.
//
// Aturan bentrok: versi terakhir yang dikirim menang (last write wins).
// Nama dan cara pemanggilan sama seperti versi lokal sebelumnya.

// Kondisi sinkronisasi satu akun (disimpan di memori + SharedPreferences).
class _SyncState {
  final Map<String, Tournament> items;
  final Set<String> pending; // perlu dikirim ke server
  final Set<String> deleted; // perlu dihapus di server
  bool migrated; // data lokal lama sudah ditandai untuk diunggah

  _SyncState(this.items, this.pending, this.deleted, this.migrated);
}

class TournamentStore {
  TournamentStore._();

  static final Map<String, _SyncState> _states = {};

  // Semua komunikasi ke server dijalankan satu per satu supaya urutannya
  // tidak tertukar (mis. kiriman lama menimpa kiriman baru).
  static Future<void> _chain = Future.value();

  // Kunci 'tournaments_<uid>' sama dengan versi lokal lama, jadi data lama
  // otomatis terbaca sebagai cache.
  static String _kItems(String uid) => 'tournaments_$uid';
  static String _kPending(String uid) => 'tournaments_pending_$uid';
  static String _kDeleted(String uid) => 'tournaments_deleted_$uid';
  static String _kMigrated(String uid) => 'tournaments_migrated_$uid';

  // ---------------------------------------------------------------
  // API untuk halaman
  // ---------------------------------------------------------------

  // Sinkron dengan server lalu kembalikan daftar terbaru. Kalau offline,
  // yang dikembalikan adalah isi cache.
  static Future<List<Tournament>> load(String userId) async {
    final s = await _stateOf(userId);
    if (userId.isEmpty) return _sorted(s);
    await _serial(() => _sync(userId, s));
    return _sorted(s);
  }

  // Hanya cache lokal (cepat, tanpa internet).
  static Future<List<Tournament>> loadCached(String userId) async {
    final s = await _stateOf(userId);
    return _sorted(s);
  }

  // Simpan ke cache sekarang, kirim ke server di belakang layar.
  static Future<void> upsert(String userId, Tournament t) async {
    final s = await _stateOf(userId);
    s.items[t.id] = t;
    s.pending.add(t.id);
    s.deleted.remove(t.id);
    await _persist(userId, s);
    _scheduleFlush(userId, s);
  }

  static Future<void> delete(String userId, String id) async {
    final s = await _stateOf(userId);
    s.items.remove(id);
    s.pending.remove(id);
    s.deleted.add(id);
    await _persist(userId, s);
    _scheduleFlush(userId, s);
  }

  // ---------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------
  static List<Tournament> _sorted(_SyncState s) =>
      s.items.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Future<T> _serial<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        completer.complete(await job());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  static void _scheduleFlush(String uid, _SyncState s) {
    if (uid.isEmpty) return;
    unawaited(_serial(() => _flush(uid, s)).catchError((_) {}));
  }

  static Future<_SyncState> _stateOf(String uid) async {
    final existing = _states[uid];
    if (existing != null) return existing;

    final prefs = await SharedPreferences.getInstance();
    final items = <String, Tournament>{};
    final raw = prefs.getString(_kItems(uid));
    if (raw != null) {
      try {
        for (final e in jsonDecode(raw) as List<dynamic>) {
          try {
            final t = Tournament.fromJson(e as Map<String, dynamic>);
            items[t.id] = t;
          } catch (_) {}
        }
      } catch (_) {}
    }
    final st = _SyncState(
      items,
      (prefs.getStringList(_kPending(uid)) ?? const <String>[]).toSet(),
      (prefs.getStringList(_kDeleted(uid)) ?? const <String>[]).toSet(),
      prefs.getBool(_kMigrated(uid)) ?? false,
    );
    // Kalau pemanggil lain sudah membuat state lebih dulu, pakai yang itu.
    return _states.putIfAbsent(uid, () => st);
  }

  static Future<void> _persist(String uid, _SyncState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kItems(uid),
      jsonEncode(s.items.values.map((t) => t.toJson()).toList()),
    );
    await prefs.setStringList(_kPending(uid), s.pending.toList());
    await prefs.setStringList(_kDeleted(uid), s.deleted.toList());
    await prefs.setBool(_kMigrated(uid), s.migrated);
  }

  static Future<Map<String, String>> _headers() async {
    final auth = AuthService.instance;
    final token = await auth.getValidToken();
    return auth.authHeaders(token);
  }

  // Ambil semua turnamen milik akun dari server.
  static Future<Map<String, Tournament>> _fetchRemote(String uid) async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/tournaments?user_id=eq.$uid&select=id,data'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final out = <String, Tournament>{};
    for (final row in jsonDecode(res.body) as List<dynamic>) {
      try {
        final r = row as Map<String, dynamic>;
        final data = Map<String, dynamic>.from(r['data'] as Map);
        out[r['id'] as String] = Tournament.fromJson(data);
      } catch (_) {
        // Baris rusak dilewati, yang lain tetap dimuat.
      }
    }
    return out;
  }

  // Tarik data server, gabungkan dengan cache, lalu kirim yang masih pending.
  static Future<void> _sync(String uid, _SyncState s) async {
    try {
      final remote = await _fetchRemote(uid);

      // Sinkron pertama: turnamen lama yang hanya ada di HP ikut diunggah.
      if (!s.migrated) {
        for (final id in s.items.keys) {
          if (!remote.containsKey(id)) s.pending.add(id);
        }
        s.migrated = true;
      }

      final merged = <String, Tournament>{};
      remote.forEach((id, t) {
        if (s.deleted.contains(id)) return; // sedang dihapus
        // Ada perubahan lokal yang belum terkirim -> versi lokal dipakai.
        merged[id] = s.pending.contains(id) ? (s.items[id] ?? t) : t;
      });
      // Turnamen baru di HP yang belum ada di server.
      for (final id in s.pending) {
        final local = s.items[id];
        if (local != null && !s.deleted.contains(id)) {
          merged.putIfAbsent(id, () => local);
        }
      }
      // Yang tidak ada di server dan tidak pending berarti sudah dihapus
      // dari perangkat lain, jadi ikut hilang dari cache.
      s.items
        ..clear()
        ..addAll(merged);
      s.pending.removeWhere((id) => !s.items.containsKey(id));
      await _persist(uid, s);
    } catch (_) {
      return; // offline / belum login / tabel belum dibuat: pakai cache saja
    }
    await _flush(uid, s);
  }

  // Kirim perubahan yang tertunda ke server.
  static Future<void> _flush(String uid, _SyncState s) async {
    try {
      final headers = await _headers();

      // 1) Penghapusan
      for (final id in s.deleted.toList()) {
        try {
          final res = await ApiClient.send(() => http.delete(
            Uri.parse(
                '${SupabaseConfig.restUrl}/tournaments?id=eq.$id&user_id=eq.$uid'),
            headers: headers,
          ));
          if (res.statusCode == 200 || res.statusCode == 204) {
            s.deleted.remove(id);
          } else {
            throw ApiClient.errorFrom(res);
          }
        } on ApiException catch (e) {
          if (e.isNetwork) break; // offline: coba lagi nanti
        }
      }

      // 2) Tambah / ubah (upsert)
      for (final id in s.pending.toList()) {
        final t = s.items[id];
        if (t == null) {
          s.pending.remove(id);
          continue;
        }
        try {
          final res = await ApiClient.send(() => http.post(
            Uri.parse('${SupabaseConfig.restUrl}/tournaments?on_conflict=id'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode({
              'id': t.id,
              'name': t.name,
              'format': t.format,
              'finished': t.finished,
              'data': t.toJson(),
            }),
          ));
          if (res.statusCode == 200 ||
              res.statusCode == 201 ||
              res.statusCode == 204) {
            // Kalau turnamen diubah lagi selama pengiriman, tetap pending
            // supaya versi terbarunya ikut terkirim.
            if (identical(s.items[id], t)) s.pending.remove(id);
          } else {
            throw ApiClient.errorFrom(res);
          }
        } on ApiException catch (e) {
          if (e.isNetwork) break; // offline: coba lagi nanti
          // Ditolak server: tetap pending, lanjut ke turnamen berikutnya.
        }
      }
    } catch (_) {
      // Belum login / sesi habis: tetap pending.
    } finally {
      await _persist(uid, s);
    }
  }
}