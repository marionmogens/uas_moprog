import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../services/auth_service.dart';

// Penjaga untuk fitur yang butuh akun (booking, favorit, riwayat).
// - Sudah login  -> mengembalikan true, lanjutkan aksinya.
// - Mode tamu    -> langsung membuka halaman Login (ada tombol Daftar di
//                   sana) dengan pesan singkat, lalu mengembalikan false.
//
// Pemakaian:
//   if (!requireLogin(context, message: 'Masuk dulu untuk memesan.')) return;
bool requireLogin(BuildContext context, {required String message}) {
  if (!AuthService.instance.isGuest) return true;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LoginPage(notice: message)),
  );
  return false;
}