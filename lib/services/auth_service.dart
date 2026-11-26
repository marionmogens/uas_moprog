import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'session_storage.dart';

// Service akun (lapisan "Service" di pola Model-Service-UI, Pertemuan 11).
// Semua komunikasi ke Supabase Auth + tabel `profiles` lewat package `http`.
// Dipakai sebagai singleton: AuthService.instance, sehingga semua halaman
// membaca user yang sama (AuthService.instance.currentUser).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SessionStorage _storage = SessionStorage();
  AuthSession? _session;
  AppUser? _currentUser;

  // Mode tamu: masuk ke aplikasi tanpa akun, hanya untuk MELIHAT lapangan/kelas.
  // Tidak disimpan di HP, jadi saat aplikasi dibuka lagi kembali ke halaman Login.
  bool _guest = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isGuest => _guest && _currentUser == null;

  void enterGuest() {
    _guest = true;
  }

  // ---------------------------------------------------------------
  // Header HTTP
  // - apikey          : publishable key, selalu dikirim.
  // - Authorization   : token milik user, hanya setelah login. (Publishable
  //                     key bukan JWT, jadi tidak dikirim sebagai Bearer.)
  // ---------------------------------------------------------------
  Map<String, String> get _baseHeaders => {
    'apikey': SupabaseConfig.publishableKey,
    'Content-Type': 'application/json',
  };

  // Dipakai juga oleh service lain nanti (lapangan, reservasi).
  Map<String, String> authHeaders(String accessToken) => {
    ..._baseHeaders,
    'Authorization': 'Bearer $accessToken',
  };

  // Header untuk permintaan BACA data publik (daftar tempat, ulasan).
  // Sudah login -> pakai token user. Tamu -> hanya apikey (peran `anon`).
  Future<Map<String, String>> readHeaders() async {
    if (_session == null) return _baseHeaders;
    return authHeaders(await getValidToken());
  }

  // ---------------------------------------------------------------
  // DAFTAR. Mengembalikan true kalau langsung login (konfirmasi email
  // dimatikan di Supabase), false kalau masih perlu konfirmasi email.
  // ---------------------------------------------------------------
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.authUrl}/signup'),
      headers: _baseHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        // 'data' masuk ke raw_user_meta_data -> dibaca trigger SQL
        // untuk mengisi tabel profiles.
        'data': {'full_name': fullName, 'phone': phone, 'role': role},
      }),
    ));
    if (res.statusCode != 200) {
      throw ApiClient.errorFrom(res);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['access_token'] == null) return false; // perlu konfirmasi email
    await _startSession(AuthSession.fromAuthResponse(json));
    return true;
  }

  // ---------------------------------------------------------------
  // MASUK
  // ---------------------------------------------------------------
  Future<void> signIn({required String email, required String password}) async {
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.authUrl}/token?grant_type=password'),
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    ));
    if (res.statusCode != 200) {
      throw ApiClient.errorFrom(res);
    }
    await _startSession(
        AuthSession.fromAuthResponse(jsonDecode(res.body) as Map<String, dynamic>));
  }

  // ---------------------------------------------------------------
  // LUPA KATA SANDI (hanya lewat email), tanpa membuka browser:
  //  1) requestPasswordReset -> Supabase mengirim email berisi KODE (OTP).
  //  2) resetPasswordWithCode -> kode diverifikasi, lalu kata sandi diganti.
  // Supaya email berisi kode, template "Reset Password" di Supabase harus
  // memuat {{ .Token }}.
  // ---------------------------------------------------------------
  Future<void> requestPasswordReset(String email) async {
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.authUrl}/recover'),
      headers: _baseHeaders,
      body: jsonEncode({'email': email}),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
  }

  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final verify = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.authUrl}/verify'),
      headers: _baseHeaders,
      body: jsonEncode({'type': 'recovery', 'email': email, 'token': code}),
    ));
    if (verify.statusCode != 200) throw ApiClient.errorFrom(verify);

    final token =
    (jsonDecode(verify.body) as Map<String, dynamic>)['access_token']
    as String?;
    if (token == null) {
      throw const ApiException('Kode tidak valid atau sudah kedaluwarsa.');
    }

    final res = await ApiClient.send(() => http.put(
      Uri.parse('${SupabaseConfig.authUrl}/user'),
      headers: authHeaders(token),
      body: jsonEncode({'password': newPassword}),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    // Sesi sementara dari kode ini tidak dipakai untuk login: dicabut.
    try {
      await http
          .post(Uri.parse('${SupabaseConfig.authUrl}/logout'),
          headers: authHeaders(token))
          .timeout(ApiClient.timeout);
    } catch (_) {}
  }

  // ---------------------------------------------------------------
  // PULIHKAN SESI saat aplikasi dibuka (dipanggil SplashPage).
  // true = user masih login. Kalau offline tapi ada profil tersimpan,
  // aplikasi tetap bisa dibuka memakai profil itu.
  // ---------------------------------------------------------------
  Future<bool> restoreSession() async {
    final saved = await _storage.loadSession();
    if (saved == null) return false;
    _session = saved;
    try {
      if (_session!.isExpired) await _refreshSession();
      _currentUser = await _fetchProfile();
      await _storage.saveProfile(_currentUser!);
      return true;
    } on ApiException catch (e) {
      if (e.isNetwork) {
        final cached = await _storage.loadProfile();
        if (cached != null) {
          _currentUser = cached;
          return true;
        }
      }
      await _clearLocal();
      return false;
    }
  }

  // Token yang pasti masih berlaku (otomatis refresh bila perlu).
  // Dipakai service lain sebelum memanggil API milik user.
  Future<String> getValidToken() async {
    final session = _session;
    if (session == null) {
      throw const ApiException('Sesi berakhir. Silakan masuk lagi.',
          statusCode: 401);
    }
    if (session.isExpired) await _refreshSession();
    return _session!.accessToken;
  }

  // ---------------------------------------------------------------
  // UBAH PROFIL (hanya nama & nomor HP; role dikunci di sisi database)
  // ---------------------------------------------------------------
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final token = await getValidToken();
    final user = _currentUser!;
    final res = await ApiClient.send(() => http.patch(
      Uri.parse('${SupabaseConfig.restUrl}/profiles?id=eq.${user.id}'),
      headers: {...authHeaders(token), 'Prefer': 'return=representation'},
      body: jsonEncode({'full_name': fullName, 'phone': phone}),
    ));
    if (res.statusCode != 200) {
      throw ApiClient.errorFrom(res);
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) throw const ApiException('Perubahan gagal disimpan.');
    _currentUser = AppUser.fromJson(list.first as Map<String, dynamic>);
    await _storage.saveProfile(_currentUser!);
  }

  Future<void> refreshProfile() async {
    if (_session == null) return;
    try {
      _currentUser = await _fetchProfile();
      await _storage.saveProfile(_currentUser!);
    } on ApiException {
      // abaikan; tidak kritis
    }
  }

  // ---------------------------------------------------------------
  // KELUAR
  // ---------------------------------------------------------------
  Future<void> signOut() async {
    final session = _session;
    if (session != null) {
      try {
        await http
            .post(Uri.parse('${SupabaseConfig.authUrl}/logout'),
            headers: authHeaders(session.accessToken))
            .timeout(ApiClient.timeout);
      } catch (_) {
        // Gagal menghubungi server tidak boleh menghalangi logout lokal.
      }
    }
    await _clearLocal();
  }

  // ---------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------
  Future<void> _startSession(AuthSession session) async {
    _guest = false;
    _session = session;
    await _storage.saveSession(session);
    _currentUser = await _fetchProfile();
    await _storage.saveProfile(_currentUser!);
  }

  Future<void> _refreshSession() async {
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.authUrl}/token?grant_type=refresh_token'),
      headers: _baseHeaders,
      body: jsonEncode({'refresh_token': _session!.refreshToken}),
    ));
    if (res.statusCode != 200) {
      throw ApiClient.errorFrom(res);
    }
    _session = AuthSession.fromAuthResponse(
        jsonDecode(res.body) as Map<String, dynamic>);
    await _storage.saveSession(_session!);
  }

  Future<AppUser> _fetchProfile() async {
    final session = _session!;
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/profiles?id=eq.${session.userId}&select=*'),
      headers: authHeaders(session.accessToken),
    ));
    if (res.statusCode != 200) {
      throw ApiClient.errorFrom(res);
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) {
      throw const ApiException(
          'Profil akun tidak ditemukan. Pastikan SQL tahap 1 sudah dijalankan.');
    }
    return AppUser.fromJson(list.first as Map<String, dynamic>);
  }

  Future<void> _clearLocal() async {
    _guest = false;
    _session = null;
    _currentUser = null;
    await _storage.clear();
  }
}