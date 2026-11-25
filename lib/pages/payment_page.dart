import 'package:flutter/material.dart';
import '../data/booking_options.dart';
import '../models/booking_draft.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../utils/formatters.dart';
import '../utils/ui_helpers.dart';
import '../widgets/selectable_option.dart';
import 'confirmation_page.dart';

class PaymentPage extends StatefulWidget {
  final BookingDraft draft;
  const PaymentPage({super.key, required this.draft});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int? _selectedMethodIndex;
  bool _paying = false; // true selama reservasi dikirim ke server

  // Data pemesan diambil dari akun yang sedang login.
  String get _name => AuthService.instance.currentUser?.fullName ?? '';
  String get _phone => AuthService.instance.currentUser?.phone ?? '';

  void _confirmPayment() {
    final method = paymentMethods[_selectedMethodIndex!];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Bayar ${formatRupiah(widget.draft.totalPrice)} menggunakan '
              '${method.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // tutup dialog dulu
              _processPayment(method);
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }

  // Simpan reservasi ke Supabase. Kalau gagal (mis. jam sudah dipesan orang
  // lain), user tetap di halaman ini dan bisa kembali untuk mengganti jadwal.
  Future<void> _processPayment(PaymentMethodOption method) async {
    setState(() => _paying = true);

    final draft = widget.draft;
    final bookingCode =
        'PDL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      await BookingService.instance.createBooking(
        draft: draft,
        bookingCode: bookingCode,
        customerName: _name,
        customerPhone: _phone,
        paymentMethod: method.name,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      showMessage(context, e.message, isError: true);
      return;
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationPage(
          customerName: _name,
          methodName: method.name,
          bookingCode: bookingCode,
          draft: draft,
        ),
      ),
          (route) => route.isFirst, // bersihkan stack sampai Home saja
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        title: const Text('Pembayaran',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total Pembayaran',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      formatRupiah(widget.draft.totalPrice),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'a.n. $_name${_phone.isNotEmpty ? ' • $_phone' : ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Pilih Metode Pembayaran'),
              const SizedBox(height: 12),
              ...List.generate(paymentMethods.length, (index) {
                final method = paymentMethods[index];
                final isSelected = _selectedMethodIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableOption(
                    selected: isSelected,
                    onTap: () => setState(() => _selectedMethodIndex = index),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(method.icon,
                            color: isSelected
                                ? Colors.pink.shade300
                                : Colors.grey.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(method.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                method.subtitle,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: Colors.pink.shade300, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedMethodIndex != null && !_paying)
                  ? _confirmPayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade300,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _paying
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Bayar Sekarang'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }
}