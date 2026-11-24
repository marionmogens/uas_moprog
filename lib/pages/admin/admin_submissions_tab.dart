import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../models/review.dart';
import '../../utils/formatters.dart';
import 'admin_actions.dart';
import 'admin_venue_detail_page.dart';

class AdminSubmissionsTab extends StatelessWidget {
  final List<PadelCourt> venues;
  final List<Review> reviews;
  final Future<void> Function() onRefresh;
  final Future<void> Function(PadelCourt venue, String decision) onDecision;

  const AdminSubmissionsTab({
    super.key,
    required this.venues,
    required this.reviews,
    required this.onRefresh,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final pending = venues.where((v) => v.status == 'menunggu').toList();
    final approved = venues.where((v) => v.status == 'disetujui').length;
    final rejected =
        venues.where((v) => v.status == 'ditolak' || v.status == 'ditangguhkan').length;
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _stat('Menunggu', '${pending.length}', Colors.orange.shade700),
              _stat('Disetujui', '$approved', Colors.green.shade600),
              _stat('Ditolak/Tunda', '$rejected', Colors.red.shade400),
              _stat('Rating rata-rata', reviews.isEmpty ? '-' : avg.toStringAsFixed(1),
                  adminColor),
            ],
          ),
          const SizedBox(height: 20),
          Text('Pengajuan menunggu persetujuan (${pending.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.task_alt, size: 48, color: Colors.green.shade300),
                  const SizedBox(height: 8),
                  const Text('Semua pengajuan sudah diproses',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          for (final v in pending) _card(context, v),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, PadelCourt v) {
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
                  width: 72,
                  height: 72,
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${v.category} • ${v.isIndoor ? 'Indoor' : 'Outdoor'} • ${formatRupiah(v.pricePerHour)}/jam',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                    Text(v.location,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                    if (v.createdAt != null)
                      Text('Diajukan ${formatShortDate(v.createdAt!)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${v.ownerName.isEmpty ? '(tanpa nama)' : v.ownerName} • ${v.ownerPhone}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AdminVenueDetailPage(venue: v)),
                  );
                  if (changed == true) onRefresh();
                },
                child: const Text('Lihat detail'),
              ),
              OutlinedButton(
                onPressed: () => onDecision(v, 'ditolak'),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200)),
                child: Text('Tolak', style: TextStyle(color: Colors.red.shade600)),
              ),
              ElevatedButton(
                onPressed: () => onDecision(v, 'disetujui'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Setujui'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}