import 'package:flutter/material.dart';
import '../../models/stats_period.dart';
import '../../models/venue_stats.dart';
import '../../services/api_exception.dart';
import '../../services/booking_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/period_chips.dart';
import '../../widgets/stat_tile.dart';
import '../venue_bookings_page.dart';
import 'admin_actions.dart';

// Tab "Pesanan" admin: total pesanan & pendapatan setiap lapangan/kelas.
// Ketuk satu baris untuk melihat daftar pesanannya.
class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  StatsPeriod _period = StatsPeriod.all;
  String? _category; // null = semua
  String _sort = 'revenue'; // revenue | orders | name
  String _query = '';
  late Future<List<VenueStats>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<VenueStats>> _load() => BookingService.instance
      .fetchVenueStats(from: _period.from, to: _period.to);

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VenueStats>>(
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
                Text(e is ApiException ? e.message : 'Gagal memuat statistik.'),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: _reload, child: const Text('Coba lagi')),
              ],
            ),
          );
        }
        return _buildContent(snap.data ?? []);
      },
    );
  }

  Widget _buildContent(List<VenueStats> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((s) {
      if (_category != null && s.category != _category) return false;
      if (q.isEmpty) return true;
      return s.venueName.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case 'orders':
        list.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
        break;
      case 'name':
        list.sort((a, b) =>
            a.venueName.toLowerCase().compareTo(b.venueName.toLowerCase()));
        break;
      default:
        list.sort((a, b) => b.revenue.compareTo(a.revenue));
    }

    final totalBookings = list.fold<int>(0, (s, v) => s + v.totalBookings);
    final revenue = list.fold<int>(0, (s, v) => s + v.revenue);
    final cancelled = list.fold<int>(0, (s, v) => s + v.cancelledBookings);

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: adminColor.withOpacity(0.18),
        onSelected: (_) => onTap(),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PeriodChips(
            selected: _period,
            color: adminColor,
            onChanged: (p) {
              _period = p;
              _reload();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Total pesanan',
                  value: '$totalBookings',
                  icon: Icons.receipt_long_outlined,
                  color: adminColor,
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
          const SizedBox(height: 6),
          Text('$cancelled pesanan dibatalkan • periode berdasarkan tanggal main',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari nama tempat atau kota...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Semua', _category == null,
                        () => setState(() => _category = null)),
                chip('Lapangan', _category == 'Lapangan',
                        () => setState(() => _category = 'Lapangan')),
                chip('Kelas', _category == 'Kelas',
                        () => setState(() => _category = 'Kelas')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Urut: pendapatan', _sort == 'revenue',
                        () => setState(() => _sort = 'revenue')),
                chip('Urut: pesanan', _sort == 'orders',
                        () => setState(() => _sort = 'orders')),
                chip('Urut: nama', _sort == 'name',
                        () => setState(() => _sort = 'name')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Tidak ada tempat')),
            ),
          for (final s in list) _buildRow(s),
        ],
      ),
    );
  }

  Widget _buildRow(VenueStats s) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VenueBookingsPage(
            venueId: s.venueId,
            venueName: s.venueName,
            accent: adminColor,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.venueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text('${s.category} • ${s.city}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text(
                    '${s.totalBookings} pesanan'
                        '${s.cancelledBookings > 0 ? ' • ${s.cancelledBookings} batal' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatRupiah(s.revenue),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}