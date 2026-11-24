import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/formatters.dart';
import '../utils/ui_helpers.dart';
import '../widgets/review_dialog.dart';

// Detail satu pesanan (dibuka dari tab Riwayat). Hanya untuk melihat:
// pesanan yang sudah dibayar tidak bisa dibatalkan.
class BookingDetailPage extends StatelessWidget {
  final Booking booking;
  const BookingDetailPage({super.key, required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case Booking.statusRejected:
        return Colors.red.shade400;
      case Booking.statusCancelled:
        return Colors.grey.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case Booking.statusRejected:
        return Icons.cancel;
      case Booking.statusCancelled:
        return Icons.remove_circle;
      default:
        return Icons.check_circle;
    }
  }

  Future<void> _review(BuildContext context) async {
    final saved = await showReviewDialog(
      context,
      venueId: booking.courtId,
      venueName: booking.courtName,
    );
    if (saved == true && context.mounted) {
      showMessage(context, 'Terima kasih! Ulasanmu tersimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final addonsTotal =
    booking.addons.fold<int>(0, (sum, a) => sum + a.price * a.quantity);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        title: const Text('Detail Pesanan',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Banner status pembayaran ----
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.statusLabel,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dipesan ${formatShortDate(booking.createdAt)}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Kode booking ----
                  _card(
                    child: Center(
                      child: Column(
                        children: [
                          Text('Kode Booking',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text(
                            booking.bookingCode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 1.5,
                              color: Colors.pink.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Rincian reservasi ----
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title('Rincian Reservasi'),
                        const SizedBox(height: 10),
                        _row('Tempat', booking.courtName),
                        _row(
                            booking.fieldName == 'Kelas'
                                ? 'Jenis'
                                : 'Lapangan',
                            booking.fieldName),
                        _row('Tanggal', formatDate(booking.bookingDate)),
                        _row('Jam', booking.timeSlot),
                        _row('Durasi', booking.duration),
                        if (booking.note.isNotEmpty)
                          _row('Catatan', booking.note),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Rincian pembayaran ----
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title('Rincian Pembayaran'),
                        const SizedBox(height: 10),
                        _row('Sewa', formatRupiah(booking.courtPrice)),
                        for (final a in booking.addons)
                          _row('${a.name} x${a.quantity}',
                              formatRupiah(a.price * a.quantity)),
                        if (booking.addons.isNotEmpty)
                          _row('Subtotal tambahan', formatRupiah(addonsTotal)),
                        const Divider(height: 22),
                        _row('Metode', booking.paymentMethod),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Dibayar',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              formatRupiah(booking.totalPrice),
                              style: TextStyle(
                                color: Colors.pink.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Data pemesan ----
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title('Data Pemesan'),
                        const SizedBox(height: 10),
                        _row('Nama', booking.customerName),
                        _row('Nomor HP',
                            booking.customerPhone.isEmpty
                                ? '-'
                                : booking.customerPhone),
                      ],
                    ),
                  ),

                  if (booking.canReview) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _review(context),
                        icon: const Icon(Icons.star_border, size: 18),
                        label: const Text('Beri Ulasan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  );

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}