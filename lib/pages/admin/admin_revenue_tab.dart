import 'package:flutter/material.dart';
import '../../config/revenue_config.dart';
import '../../models/revenue.dart';
import '../../services/api_exception.dart';
import '../../services/revenue_service.dart';
import '../../utils/formatters.dart';
import 'admin_actions.dart';

// Tab "Pendapatan" admin: total pendapatan keseluruhan, keuntungan bersih
// admin (komisi 20%), bagian pemilik (80%), dan rinciannya per tempat.
class AdminRevenueTab extends StatefulWidget {
  const AdminRevenueTab({super.key});

  @override
  State<AdminRevenueTab> createState() => _AdminRevenueTabState();
}

class _AdminRevenueTabState extends State<AdminRevenueTab> {
  late Future<RevenueSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = RevenueService.instance.fetch();
  }

  Future<void> _refresh() async {
    final next = RevenueService.instance.fetch();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RevenueSummary>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final e = snap.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(e is ApiException ? e.message : 'Gagal memuat data.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        final summary = snap.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildTotalCard(summary),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _shareCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Keuntungan Bersih Admin',
                      percent: RevenueConfig.platformPercent,
                      amount: summary.platformShare,
                      color: adminColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _shareCard(
                      icon: Icons.storefront_outlined,
                      title: 'Bagian Pemilik Tempat',
                      percent: RevenueConfig.ownerPercent,
                      amount: summary.ownerShare,
                      color: Colors.pink.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Pendapatan per Tempat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Hanya pesanan yang sudah dibayar yang dihitung.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              if (summary.venues.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Belum ada tempat')),
                ),
              for (final v in summary.venues) _venueTile(v),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalCard(RevenueSummary s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Pendapatan Keseluruhan',
              style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupiah(s.totalGross),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.totalBookings} pesanan berbayar dari ${s.venues.length} tempat',
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _shareCard({
    required IconData icon,
    required String title,
    required int percent,
    required int amount,
    required Color color,
  }) {
    return Container(
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
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$percent%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatRupiah(amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          ),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _venueTile(VenueRevenue v) {
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
          Text(v.venueName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 2),
          Text('${v.ownerName} • ${v.bookingCount} pesanan',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          const Divider(height: 20),
          Row(
            children: [
              _mini('Total', v.gross, Colors.black87),
              _mini('Admin (${RevenueConfig.platformPercent}%)',
                  v.platformShare, adminColor),
              _mini('Pemilik (${RevenueConfig.ownerPercent}%)', v.ownerShare,
                  Colors.pink.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, int amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatRupiah(amount),
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5, color: color)),
          ),
        ],
      ),
    );
  }
}