import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_exception.dart';
import '../services/booking_service.dart';
import '../utils/formatters.dart';
import '../utils/ui_helpers.dart';
import '../widgets/booking_phase_chip.dart';
import '../widgets/review_dialog.dart';

// Tab Riwayat: dua bagian.
//   Aktif   = reservasi yang belum selesai (akan datang / sedang berlangsung)
//   Riwayat = reservasi selesai, dibatalkan, atau ditolak.
// Ulasan/rating hanya bisa diberikan dari bagian Riwayat (jadwal sudah lewat).
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Booking>> _future;
  int _tab = 0; // 0 = Aktif, 1 = Riwayat

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

  Future<void> _cancel(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Batalkan Reservasi'),
        content: Text(
          'Batalkan reservasi ${booking.courtName} pada '
              '${formatDate(booking.bookingDate)} (${booking.timeSlot})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, batalkan',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await BookingService.instance.cancelBooking(booking.id);
      if (!mounted) return;
      showMessage(context, 'Reservasi dibatalkan');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    }
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
                      'Reservasi Saya',
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
                  return _buildLists(snapshot.data ?? []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLists(List<Booking> all) {
    // Aktif: yang paling dekat jadwalnya di atas.
    final active = all.where((b) => b.isActive).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    // Riwayat: yang paling baru selesai di atas.
    final history = all.where((b) => !b.isActive).toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
    final list = _tab == 0 ? active : history;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, label: Text('Aktif (${active.length})')),
                ButtonSegment(
                    value: 1, label: Text('Riwayat (${history.length})')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.pink.shade50,
                selectedForegroundColor: Colors.pink.shade400,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: list.isEmpty
                ? ListView(children: [_buildEmpty(_tab == 0)])
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  _buildBookingCard(list[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool isActiveTab) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActiveTab ? Icons.event_available_outlined : Icons.history,
              size: 56, color: Colors.pink.shade200),
          const SizedBox(height: 12),
          Text(
              isActiveTab ? 'Belum ada reservasi aktif' : 'Belum ada riwayat',
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            isActiveTab
                ? 'Reservasi yang akan datang akan muncul di sini.'
                : 'Reservasi yang sudah selesai atau dibatalkan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
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

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
              BookingPhaseChip(booking: booking),
            ],
          ),
          const SizedBox(height: 4),
          Text('Kode: ${booking.bookingCode}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today_outlined,
              formatDate(booking.bookingDate)),
          _infoRow(Icons.schedule, '${booking.timeSlot} • ${booking.duration}'),
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
              // Hanya muncul di Riwayat, setelah jadwal selesai.
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
              // Hanya muncul di Aktif, sebelum jadwal dimulai.
              if (booking.canCancel)
                OutlinedButton(
                  onPressed: () => _cancel(booking),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Batalkan',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          if (booking.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ulasan bisa diberikan setelah jadwal selesai.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
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