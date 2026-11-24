// Fungsi validasi untuk TextFormField. Mengembalikan null kalau valid,
// atau teks pesan error kalau tidak valid. Dipisah di sini supaya form
// Login, Daftar, dan Akun memakai aturan yang sama (tidak duplikat).
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Format email tidak valid';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    if (value.length < 6) return 'Kata sandi minimal 6 karakter';
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nomor HP wajib diisi';
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(text)) {
      return 'Nomor HP tidak valid (9-15 angka)';
    }
    return null;
  }
}