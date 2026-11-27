import 'package:flutter/material.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_button.dart';
import '../home_page.dart';
import '../role_router.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'verify_email_page.dart';

class LoginPage extends StatefulWidget {
  // Pesan opsional di atas form, diisi saat tamu diarahkan ke sini
  // (mis. "Masuk dulu untuk melihat riwayat pesananmu.").
  final String? notice;
  const LoginPage({super.key, this.notice});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // validate() menjalankan semua validator di form; false = ada yang salah.
    if (!_formKey.currentState!.validate()) return;

    var needVerify = false;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Hapus semua halaman sebelumnya agar tombol Back tidak kembali ke Login.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => homeForUser(AuthService.instance.currentUser!),
        ),
            (route) => false,
      );
    } on ApiException catch (e) {
      if (e.code == ApiException.emailNotConfirmed) {
        needVerify = true; // ditangani di bawah, setelah loading selesai
      } else if (mounted) {
        showMessage(context, e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (needVerify && mounted) {
      await _promptVerifyEmail(_emailController.text.trim());
    }
  }

  // Email belum diverifikasi: tawarkan kirim kode lalu buka halaman verifikasi.
  Future<void> _promptVerifyEmail(String email) async {
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Email belum diverifikasi'),
        content: Text(
          'Akun $email belum diverifikasi. Kami kirim kode verifikasi '
              'ke emailmu supaya kamu bisa masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim Kode'),
          ),
        ],
      ),
    );
    if (send != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.resendSignupCode(email);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyEmailPage(email: email)),
      );
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Lupa kata sandi: halaman ini mengembalikan email kalau kata sandi
  // berhasil diganti, supaya kolom email di sini terisi otomatis.
  Future<void> _openForgotPassword() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ForgotPasswordPage(initialEmail: _emailController.text.trim()),
      ),
    );
    if (email != null && mounted) {
      _emailController.text = email;
      _passwordController.clear();
      showMessage(context, 'Kata sandi berhasil diubah. Silakan masuk.');
    }
  }

  // Masuk sebagai tamu: bisa melihat lapangan/kelas, tapi booking, favorit,
  // dan riwayat akan mengarahkan kembali ke Login / Daftar.
  void _continueAsGuest() {
    AuthService.instance.enterGuest();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = AuthService.instance.isGuest;

    return Scaffold(
      // Kalau dibuka dari mode tamu, ada tombol kembali ke aplikasi.
      appBar: isGuest
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            // maxWidth: di jendela desktop yang lebar, form tetap berukuran
            // seperti di HP (tidak melebar aneh).
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Selamat Datang',
                      subtitle: 'Masuk untuk reservasi lapangan padel',
                    ),
                    if (widget.notice != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.pink.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.pink.shade300),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.notice!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          Validators.required(v, field: 'Kata sandi'),
                      onFieldSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _openForgotPassword,
                        child: const Text('Lupa kata sandi?'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PrimaryButton(
                      label: 'Masuk',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Belum punya akun?',
                            style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const RegisterPage(),
                            ),
                          ),
                          child: const Text('Daftar'),
                        ),
                      ],
                    ),
                    // Tombol tamu hanya muncul kalau belum dalam mode tamu.
                    if (!isGuest) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _continueAsGuest,
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('Masuk sebagai Tamu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.pink.shade300,
                          side: BorderSide(color: Colors.pink.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lihat lapangan & kelas dulu tanpa akun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}