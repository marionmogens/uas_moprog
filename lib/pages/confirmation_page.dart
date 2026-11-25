import 'package:flutter/material.dart';
import '../models/booking_draft.dart';
import '../utils/formatters.dart';

class ConfirmationPage extends StatelessWidget {
  final String customerName;
  final String methodName;
  final String bookingCode; // dibuat di PaymentPage, jadi tidak berubah-ubah
  final BookingDraft draft; // pesanan yang baru dibayar

  const ConfirmationPage({
    super.key,
    required this.customerName,
    required this.methodName,
    required this.bookingCode,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 72),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terima kasih, $customerName. Pembayaran diterima dan '
                      'reservasi Anda sudah terkonfirmasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Kode Booking',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text(
                              bookingCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1.5,
                                color: Colors.pink.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      const Text('Rincian Reservasi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      Text(
                        draft.court.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        '${draft.fieldName} • ${formatDate(draft.date)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Text(
                        '${draft.timeSlot} • ${draft.duration}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (draft.addons.isNotEmpty)
                        Text(
                          'Add-on: ${draft.addonsText}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      if (draft.note.isNotEmpty)
                        Text(
                          'Catatan: ${draft.note}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      const Divider(height: 24),
                      _detailRow('Total Dibayar', formatRupiah(draft.totalPrice)),
                      const SizedBox(height: 6),
                      _detailRow('Metode Pembayaran', methodName),
                      const SizedBox(height: 6),
                      _detailRow('Status', 'Pembayaran Berhasil'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Kembali ke Home, bersihkan seluruh stack navigasi
                      // supaya tombol back tidak balik lagi ke halaman bayar.
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Kembali ke Beranda'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}