import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/stats_period.dart';
import '../services/api_exception.dart';
import '../services/booking_service.dart';
import '../utils/formatters.dart';
import '../widgets/booking_phase_chip.dart';
import '../widgets/period_chips.dart';
import '../widgets/stat_tile.dart';

// Daftar pesanan satu tempat + ringkasan total. Dipakai pemilik (dari
// "Tempat Saya") dan admin (dari tab Pesanan / detail tempat).
class VenueBookingsPage extends StatefulWidget {
  final String venueId;
  final String venueName;
  final Color accent;

  const VenueBookingsPage({
    super.key,
    required this.venueId,
    required this.venueName,
    this.accent = const Color(0xFFF06292),
  });

  @override
  State<VenueBookingsPage> createState() => _VenueBookingsPageState();
}

class _VenueBookingsPageState extends State<VenueBookingsPage> {
  StatsPeriod _period = StatsPeriod.all;
  String _phase = 'semua'; // semua | aktif | selesai | batal
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Booking>> _load() => BookingService.instance
      .fetchForVenue(widget.venueId, from: _period.from, to: _period.to);

  void _reload() => setState(() => _future = _load());

  bool _match(Booking b) {
    switch (_phase) {
      case 'aktif':
        return b.isActive;
      case 'selesai':
        return b.isFinished;
      case 'batal':
        return b.isCancelledOrRejected;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: widget.accent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Pesanan: ${widget.venueName}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: PeriodChips(
                    selected: _period,
                    color: widget.accent,
                    onChanged: (p) {
                      _period = p;
                      _reload();
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Booking>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        final e = snap.error;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e is ApiException
                                  ? e.message
                                  : 'Gagal memuat pesanan.'),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                  onPressed: _reload,
                                  child: const Text('Coba lagi')),
                            ],
                          ),
                        );
                      }
                      return _buildContent(snap.data ?? []);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Booking> all) {
    final counted = all.where((b) => !b.isCancelledOrRejected).toList();
    final revenue = counted.fold<int>(0, (s, b) => s + b.totalPrice);
    final upcoming = counted.where((b) => b.isActive).length;
    final finished = counted.length - upcoming;
    final cancelled = all.length - counted.length;
    final shown = all.where(_match).toList();

    Widget chip(String label, String value) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: _phase == value,
        selectedColor: widget.accent.withOpacity(0.18),
        onSelected: (_) => setState(() => _phase = value),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Total pesanan',
                  value: '${counted.length}',
                  icon: Icons.receipt_long_outlined,
                  color: widget.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Total pendapatan',
                  value: formatRupiah(revenue),
                  icon: Icons.payments_outlined,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Akan datang',
                  value: '$upcoming',
                  icon: Icons.event_available_outlined,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Selesai',
                  value: '$finished',
                  icon: Icons.task_alt,
                  color: Colors.teal.shade600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Dibatalkan',
                  value: '$cancelled',
                  icon: Icons.cancel_outlined,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Pendapatan = total harga pesanan yang tidak dibatalkan, '
                  'dihitung dari tanggal main.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Semua (${all.length})', 'semua'),
                chip('Akan datang', 'aktif'),
                chip('Selesai', 'selesai'),
                chip('Dibatalkan', 'batal'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada pesanan')),
            ),
          for (final b in shown) _buildTile(b),
        ],
      ),
    );
  }

  Widget _buildTile(Booking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            children: [
              Expanded(
                child: Text(
                  b.customerName.isEmpty ? '(tanpa nama)' : b.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              BookingPhaseChip(booking: b),
            ],
          ),
          if (b.customerPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(b.customerPhone,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ),
          const SizedBox(height: 8),
          _row(Icons.calendar_today_outlined,
              '${formatDate(b.bookingDate)} • ${b.timeSlot}'),
          _row(Icons.place_outlined, b.fieldName),
          if (b.addons.isNotEmpty) _row(Icons.add_circle_outline, b.addonsText),
          if (b.note.isNotEmpty) _row(Icons.sticky_note_2_outlined, b.note),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('${b.bookingCode} • ${b.paymentMethod}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
              Text(
                formatRupiah(b.totalPrice),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: b.isCancelledOrRejected
                      ? Colors.grey.shade500
                      : widget.accent,
                  decoration: b.isCancelledOrRejected
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
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