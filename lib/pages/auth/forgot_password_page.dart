import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_button.dart';

// Lupa kata sandi, hanya memakai email. Dua langkah dalam satu halaman:
//  1) Masukkan email -> Supabase mengirim KODE verifikasi ke email itu.
//  2) Masukkan kode + kata sandi baru -> kata sandi diganti.
// Tidak perlu kata sandi lama. Kalau berhasil, halaman ini menutup diri dan
// mengembalikan email ke halaman Login.
class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _resendSeconds = 60;

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false; // false = langkah 1 (email), true = langkah 2 (kode)
  bool _loading = false;
  bool _obscure = true;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  // Langkah 1: tombol "Kirim Kode" (email divalidasi dulu).
  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    await _requestCode();
  }

  // Dipakai tombol "Kirim Kode" dan "Kirim ulang kode".
  Future<void> _requestCode() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance
          .requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCountdown();
      // Pesan sengaja netral: tidak membocorkan apakah email terdaftar.
      showMessage(
          context, 'Jika email terdaftar, kode verifikasi sudah dikirim.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Langkah 2: verifikasi kode lalu ganti kata sandi.
  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      await AuthService.instance.resetPasswordWithCode(
        email: email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, email); // kembali ke Login
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeEmail() {
    _timer?.cancel();
    setState(() {
      _codeSent = false;
      _secondsLeft = 0;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: 'Lupa Kata Sandi',
                    subtitle: _codeSent
                        ? 'Masukkan kode dari email dan kata sandi baru'
                        : 'Kami kirim kode verifikasi ke emailmu',
                  ),
                  const SizedBox(height: 28),
                  if (_codeSent) _buildResetStep() else _buildEmailStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _submitEmail(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Kirim Kode',
            loading: _loading,
            onPressed: _submitEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 18, color: Colors.pink.shade300),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kode dikirim ke ${_emailController.text.trim()}. '
                        'Cek juga folder spam.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _codeController,
            label: 'Kode Verifikasi',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return 'Kode wajib diisi';
              if (!RegExp(r'^[0-9]{6,10}$').hasMatch(text)) {
                return 'Kode berupa 6-10 angka';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _passwordController,
            label: 'Kata Sandi Baru',
            icon: Icons.lock_outline,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
            suffix: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _confirmController,
            label: 'Ulangi Kata Sandi Baru',
            icon: Icons.lock_reset_outlined,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitReset(),
            validator: (v) => v != _passwordController.text
                ? 'Kata sandi tidak sama'
                : null,
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Simpan Kata Sandi Baru',
            loading: _loading,
            onPressed: _submitReset,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed:
                (_loading || _secondsLeft > 0) ? null : _requestCode,
                child: Text(_secondsLeft > 0
                    ? 'Kirim ulang ($_secondsLeft dtk)'
                    : 'Kirim ulang kode'),
              ),
              TextButton(
                onPressed: _loading ? null : _changeEmail,
                child: const Text('Ganti email'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}