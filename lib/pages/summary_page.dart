import 'package:flutter/material.dart';
import '../models/booking_draft.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import 'payment_page.dart';

class SummaryPage extends StatelessWidget {
  final BookingDraft draft;
  const SummaryPage({super.key, required this.draft});

  void _goToPayment(BuildContext context) {
    // Nama & nomor HP tidak perlu diisi lagi: diambil dari akun yang login.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentPage(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final phone = (user?.phone.isNotEmpty ?? false) ? user!.phone : '-';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        title: const Text('Ringkasan Reservasi',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Rincian Reservasi'),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.court.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                            draft.court.category == 'Kelas'
                                ? 'Lokasi'
                                : 'Lapangan',
                            draft.fieldName),
                        _infoRow('Tanggal', formatDate(draft.date)),
                        _infoRow('Jam', draft.timeSlot),
                        _infoRow('Durasi', draft.duration),
                        if (draft.note.isNotEmpty)
                          _infoRow('Catatan', draft.note),
                        const Divider(height: 24),
                        _priceRow('Sewa', formatRupiah(draft.courtPrice)),
                        for (final a in draft.addons)
                          _priceRow('${a.name} x${a.quantity}',
                              formatRupiah(a.subtotal)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bayar',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              formatRupiah(draft.totalPrice),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade300,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Data Pemesan'),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label dengan lebar tetap + nilai rata kiri, supaya
                        // Nama dan Nomor HP sejajar rapi.
                        _infoRow('Nama', user?.fullName ?? '-',
                            icon: Icons.person_outline),
                        _infoRow('Nomor HP', phone,
                            icon: Icons.phone_outlined),
                        const SizedBox(height: 4),
                        Text(
                          'Data diambil dari akunmu. Ubah lewat tab Akun bila perlu.',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Lanjut ke Pembayaran'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _card({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );
}

// Baris "label : nilai". Lebar kolom label selalu sama sehingga semua
// nilai mulai di posisi yang sama dan tampak sejajar.
Widget _infoRow(String label, String value, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: icon != null ? 68 : 90,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        const Text(':  ', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Widget _priceRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
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