import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/primary_button.dart';
import '../role_router.dart';

// Verifikasi email akun baru. Kode 6 angka dikirim Supabase ke email;
// kode benar -> email terverifikasi dan pengguna langsung masuk ke aplikasi.
// Halaman ini dibuka setelah Daftar, atau dari Masuk bila email belum
// diverifikasi (kode sudah dikirim tepat sebelum halaman ini dibuka).
class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const int _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _loading = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(); // kode baru saja dikirim, kirim ulang menunggu 60 detik
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = _resendSeconds;
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

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.verifySignupCode(
        email: widget.email,
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => homeForUser(AuthService.instance.currentUser!),
        ),
            (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.resendSignupCode(widget.email);
      if (!mounted) return;
      setState(_startCountdown);
      showMessage(context, 'Kode verifikasi baru sudah dikirim.');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Verifikasi Email',
                      subtitle: 'Masukkan kode yang kami kirim ke emailmu',
                    ),
                    const SizedBox(height: 24),
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
                              'Kode dikirim ke ${widget.email}. '
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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verify(),
                      validator: (v) {
                        final text = v?.trim() ?? '';
                        if (text.isEmpty) return 'Kode wajib diisi';
                        if (!RegExp(r'^[0-9]{6,10}$').hasMatch(text)) {
                          return 'Kode berupa 6-10 angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Verifikasi',
                      loading: _loading,
                      onPressed: _verify,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: (_loading || _secondsLeft > 0)
                              ? null
                              : _resend,
                          child: Text(_secondsLeft > 0
                              ? 'Kirim ulang ($_secondsLeft dtk)'
                              : 'Kirim ulang kode'),
                        ),
                        TextButton(
                          onPressed:
                          _loading ? null : () => Navigator.pop(context),
                          child: const Text('Salah email?'),
                        ),
                      ],
                    ),
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