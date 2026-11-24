import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_exception.dart';
import '../services/booking_service.dart';
import '../utils/formatters.dart';
import '../utils/ui_helpers.dart';
import '../widgets/review_dialog.dart';
import 'booking_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = BookingService.instance.fetchMyBookings();
  }

  void _reload() {
    setState(() {
      _future = BookingService.instance.fetchMyBookings();
    });
  }

  void _openDetail(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(booking: booking),
      ),
    );
  }

  Future<void> _review(Booking booking) async {
    final saved = await showReviewDialog(
      context,
      venueId: booking.courtId,
      venueName: booking.courtName,
    );
    if (saved == true && mounted) {
      showMessage(context, 'Terima kasih! Ulasanmu tersimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Riwayat Reservasi',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: _reload,
                    icon: Icon(Icons.refresh, color: Colors.pink.shade300),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Booking>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return _buildError(error is ApiException
                        ? error.message
                        : 'Terjadi kesalahan saat memuat riwayat.');
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) return _buildEmpty();
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) =>
                        _buildBookingCard(bookings[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: Colors.pink.shade200),
            const SizedBox(height: 12),
            const Text('Belum ada reservasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Pesanan yang sudah kamu bayar akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case Booking.statusRejected:
        return Colors.red.shade400;
      case Booking.statusCancelled:
        return Colors.grey.shade600;
      default:
        return Colors.green.shade600; // pembayaran berhasil
    }
  }

  Widget _buildBookingCard(Booking booking) {
    final color = _statusColor(booking.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openDetail(booking),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking.courtName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.statusLabel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Kode: ${booking.bookingCode}',
                    style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                _infoRow(Icons.calendar_today_outlined,
                    formatDate(booking.bookingDate)),
                _infoRow(Icons.schedule,
                    '${booking.timeSlot} • ${booking.duration}'),
                _infoRow(Icons.place_outlined, booking.fieldName),
                if (booking.addons.isNotEmpty)
                  _infoRow(Icons.add_circle_outline, booking.addonsText),
                if (booking.note.isNotEmpty)
                  _infoRow(Icons.sticky_note_2_outlined, booking.note),
                const Divider(height: 22),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total • ${booking.paymentMethod}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                        Text(
                          formatRupiah(booking.totalPrice),
                          style: TextStyle(
                            color: Colors.pink.shade300,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (booking.canReview)
                      OutlinedButton.icon(
                        onPressed: () => _review(booking),
                        icon: const Icon(Icons.star_border, size: 16),
                        label: const Text('Beri Ulasan',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () => _openDetail(booking),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.pink.shade300),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Lihat Detail',
                              style: TextStyle(fontSize: 12)),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}