import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/help_page.dart';
import 'primary_button.dart';

// Isi tab "Akun" untuk tamu: ajakan masuk / daftar + akses Pusat Bantuan.
class GuestAccountView extends StatelessWidget {
  const GuestAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 72, color: Colors.pink.shade200),
              const SizedBox(height: 12),
              const Text(
                'Kamu masuk sebagai tamu',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Masuk atau daftar untuk memesan lapangan, menyimpan '
                    'favorit, dan melihat riwayat pesanan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Masuk',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink.shade300,
                  side: BorderSide(color: Colors.pink.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Daftar Akun Baru'),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                ),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Pusat Bantuan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}