import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../models/review.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import 'admin_actions.dart';
import 'admin_venue_detail_page.dart';

class AdminVenuesTab extends StatefulWidget {
  final List<PadelCourt> venues;
  final List<Review> reviews;
  final Future<void> Function() onRefresh;
  final Future<void> Function(PadelCourt venue, String decision) onDecision;

  const AdminVenuesTab({
    super.key,
    required this.venues,
    required this.reviews,
    required this.onRefresh,
    required this.onDecision,
  });

  @override
  State<AdminVenuesTab> createState() => _AdminVenuesTabState();
}

class _AdminVenuesTabState extends State<AdminVenuesTab> {
  static const _filters = <String?, String>{
    null: 'Semua',
    'disetujui': 'Disetujui',
    'menunggu': 'Menunggu',
    'ditolak': 'Ditolak',
    'ditangguhkan': 'Ditangguhkan',
  };

  String? _status;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = widget.venues.where((v) {
      if (_status != null && v.status != _status) return false;
      if (q.isEmpty) return true;
      return v.name.toLowerCase().contains(q) ||
          v.city.toLowerCase().contains(q) ||
          v.ownerName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari nama tempat, kota, atau pemilik...',
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
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final e in _filters.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    selected: _status == e.key,
                    selectedColor: adminColor.withOpacity(0.18),
                    onSelected: (_) => setState(() => _status = e.key),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: list.isEmpty
                ? ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Tidak ada tempat')),
            ])
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _tile(context, list[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, PadelCourt v) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => AdminVenueDetailPage(venue: v)),
        );
        if (changed == true) widget.onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text('${v.category} • ${v.city} • ${formatRupiah(v.pricePerHour)}/jam',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      VenueStatusChip(status: v.status),
                      const Spacer(),
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        v.reviewCount == 0
                            ? 'Belum ada ulasan'
                            : '${v.rating} (${v.reviewCount})',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}