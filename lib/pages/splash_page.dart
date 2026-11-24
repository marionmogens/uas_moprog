import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';
import 'role_router.dart';

// Halaman pertama saat aplikasi dibuka: cek apakah masih ada sesi login
// tersimpan (SharedPreferences). Kalau ada -> langsung ke beranda sesuai
// peran; kalau tidak -> halaman Login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final restored = await AuthService.instance.restoreSession();
    if (!mounted) return;
    final Widget next = restored
        ? homeForUser(AuthService.instance.currentUser!)
        : const LoginPage();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade300,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis, color: Colors.white, size: 72),
            SizedBox(height: 12),
            Text(
              'PadelBook',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}