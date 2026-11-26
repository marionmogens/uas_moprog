import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../models/stats_period.dart';
import '../../models/venue_stats.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/venue_service.dart';
import '../../utils/formatters.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/period_chips.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_chip.dart';
import '../venue_bookings_page.dart';
import 'venue_form_page.dart';

// "Tempat Saya": daftar tempat yang diajukan user + status persetujuannya.
// Dibuka dari tab Akun (pelanggan maupun pemilik).
class MyVenuesPage extends StatefulWidget {
  const MyVenuesPage({super.key});

  @override
  State<MyVenuesPage> createState() => _MyVenuesPageState();
}

class _MyVenuesPageState extends State<MyVenuesPage> {
  late Future<List<PadelCourt>> _future;

  // Statistik pesanan per tempat (total pesanan & pendapatan).
  StatsPeriod _period = StatsPeriod.all;
  late Future<Map<String, VenueStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _statsFuture = _loadStats();
  }

  Future<Map<String, VenueStats>> _loadStats() async {
    try {
      final list = await BookingService.instance
          .fetchVenueStats(from: _period.from, to: _period.to);
      return {for (final s in list) s.venueId: s};
    } on ApiException {
      return {}; // statistik gagal dimuat tidak boleh merusak halaman
    }
  }

  Future<List<PadelCourt>> _load() async {
    final list = await VenueService.instance.fetchMine();
    // Peran bisa berubah jadi 'pemilik' setelah disetujui admin.
    await AuthService.instance.refreshProfile();
    return list;
  }

  void _reload() => setState(() {
    _future = _load();
    _statsFuture = _loadStats();
  });

  void _changePeriod(StatsPeriod p) => setState(() {
    _period = p;
    _statsFuture = _loadStats();
  });

  Future<void> _openForm([PadelCourt? venue]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VenueFormPage(existing: venue)),
    );
    if (saved == true) {
      if (mounted) {
        showMessage(context,
            venue == null ? 'Pengajuan terkirim. Menunggu persetujuan admin.' : 'Perubahan disimpan');
      }
      _reload();
    }
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    try {
      await action();
      if (!mounted) return;
      showMessage(context, okMessage);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Tempat Saya',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.pink.shade300,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tempat'),
      ),
      body: FutureBuilder<List<PadelCourt>>(
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
                  Text(e is ApiException ? e.message : 'Gagal memuat data.'),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _reload, child: const Text('Coba lagi')),
                ],
              ),
            );
          }
          final venues = snap.data ?? [];
          if (venues.isEmpty) return _buildEmpty();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: FutureBuilder<Map<String, VenueStats>>(
              future: _statsFuture,
              builder: (context, statsSnap) {
                final stats = statsSnap.data ?? {};
                final hasApproved = venues.any((v) => v.status == 'disetujui');
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    if (hasApproved) _buildSummary(stats),
                    for (final v in venues) _buildCard(v, stats[v.id]),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Ringkasan seluruh tempat milik user: total pesanan & pendapatan.
  Widget _buildSummary(Map<String, VenueStats> stats) {
    final totalBookings =
    stats.values.fold<int>(0, (s, v) => s + v.totalBookings);
    final revenue = stats.values.fold<int>(0, (s, v) => s + v.revenue);
    final cancelled =
    stats.values.fold<int>(0, (s, v) => s + v.cancelledBookings);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pesanan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          PeriodChips(
              selected: _period,
              color: Colors.pink.shade300,
              onChanged: _changePeriod),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Total pesanan',
                  value: '$totalBookings',
                  icon: Icons.receipt_long_outlined,
                  color: Colors.pink.shade300,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Pendapatan',
                  value: formatRupiah(revenue),
                  icon: Icons.payments_outlined,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$cancelled pesanan dibatalkan pada periode ini',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    Widget step(int n, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.pink.shade100,
            child: Text('$n', style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined, size: 64, color: Colors.pink.shade200),
              const SizedBox(height: 12),
              const Text('Punya lapangan padel?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              Text('Daftarkan lapangan atau kelasmu dan terima pesanan lewat PadelBook.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),
              step(1, 'Isi data tempat (lokasi, harga, jam, fasilitas, foto).'),
              step(2, 'Admin meninjau pengajuanmu.'),
              step(3, 'Setelah disetujui, tempat tampil di Beranda dan kamu menjadi Pemilik Tempat.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Daftarkan Tempat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(PadelCourt v, VenueStats? stat) {
    final approved = v.status == 'disetujui';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    v.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.sports_tennis, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${v.category} • ${v.city} • ${formatRupiah(v.pricePerHour)}/jam',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    VenueStatusChip(status: v.status),
                  ],
                ),
              ),
            ],
          ),
          if (v.rejectReason.isNotEmpty &&
              (v.status == 'ditolak' || v.status == 'ditangguhkan')) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Alasan admin: ${v.rejectReason}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ),
          ],
          if (approved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star, size: 15, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  v.reviewCount == 0
                      ? 'Belum ada ulasan'
                      : '${v.rating} (${v.reviewCount} ulasan)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (stat != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 15, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${stat.totalBookings} pesanan • ${formatRupiah(stat.revenue)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            SwitchListTile(
              value: v.isAvailable,
              onChanged: (on) => _run(
                      () => VenueService.instance.setAccepting(v.id, on),
                  on ? 'Tempat kembali menerima pesanan' : 'Tempat tidak menerima pesanan'),
              activeColor: Colors.pink.shade300,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Menerima pesanan', style: TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              if (approved)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueBookingsPage(
                        venueId: v.id,
                        venueName: v.name,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text('Lihat Pesanan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    foregroundColor: Colors.white,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _openForm(v),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Ubah'),
              ),
              if (v.status == 'ditolak')
                ElevatedButton(
                  onPressed: () => _run(
                          () => VenueService.instance.resubmit(v.id), 'Diajukan ulang ke admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ajukan Ulang'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}