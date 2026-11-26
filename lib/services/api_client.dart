import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

class ApiClient {
  ApiClient._();

  static const Duration timeout = Duration(seconds: 15);

  static Future<http.Response> send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Koneksi terlalu lama. Coba lagi.',
          isNetwork: true);
    } catch (_) {
      throw const ApiException(
          'Tidak bisa terhubung ke internet. Periksa koneksimu.',
          isNetwork: true);
    }
  }

  static ApiException errorFrom(http.Response res) {
    return ApiException(_message(res), statusCode: res.statusCode);
  }

  static String _message(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final raw = body['msg'] ??
            body['error_description'] ??
            body['message'] ??
            body['error'];
        if (raw != null) return _translate(raw.toString());
      }
    } catch (_) {}
    return 'Terjadi kesalahan (kode ${res.statusCode}).';
  }

  static String _translate(String message) {
    final m = message.toLowerCase();
    if (m.contains('slot_taken')) {
      return 'Jam yang kamu pilih baru saja dipesan orang lain. '
          'Kembali dan pilih jadwal lain.';
    }
    if (m.contains('venue_closed')) {
      return 'Tempat ini sedang tidak menerima pesanan. '
          'Coba lagi nanti atau pilih tempat lain.';
    }
    if (m.contains('not_admin')) {
      return 'Hanya admin yang bisa melakukan tindakan ini.';
    }
    if (m.contains('reason_required')) {
      return 'Alasan wajib diisi.';
    }
    if (m.contains('cannot_resubmit')) {
      return 'Pengajuan ini tidak bisa diajukan ulang.';
    }
    if (m.contains('venue_not_found')) {
      return 'Data tempat tidak ditemukan.';
    }
    if (m.contains('invalid_decision')) {
      return 'Keputusan tidak valid.';
    }
    if (m.contains('check constraint')) {
      return 'Ada isian yang tidak valid. Periksa kembali data yang kamu masukkan.';
    }
    if (m.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (m.contains('already registered') ||
        m.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (m.contains('at least 6') || m.contains('weak password')) {
      return 'Kata sandi terlalu lemah (minimal 6 karakter).';
    }
    if (m.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek kotak masuk emailmu.';
    }
    if (m.contains('for security purposes') || m.contains('once every')) {
      return 'Tunggu sekitar 1 menit sebelum meminta kode lagi.';
    }
    if (m.contains('expired or is invalid') || m.contains('otp_expired')) {
      return 'Kode salah atau sudah kedaluwarsa. Minta kode baru.';
    }
    if (m.contains('different from the old password')) {
      return 'Kata sandi baru harus berbeda dari kata sandi lama.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    }
    if (m.contains('invalid email') || m.contains('unable to validate email')) {
      return 'Format email tidak valid.';
    }
    if (m.contains('jwt expired')) {
      return 'Sesi berakhir. Silakan masuk lagi.';
    }
    if (m.contains('permission denied') || m.contains('row-level security')) {
      return 'Kamu tidak punya izin untuk tindakan ini. '
          'Pastikan SQL Supabase sudah dijalankan.';
    }
    return message;
  }
}