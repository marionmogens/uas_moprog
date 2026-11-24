import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../utils/formatters.dart';
import '../../widgets/facility_chip.dart';
import '../../widgets/reviews_section.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/status_chip.dart';
import 'admin_actions.dart';

class AdminVenueDetailPage extends StatefulWidget {
  final PadelCourt venue;
  const AdminVenueDetailPage({super.key, required this.venue});

  @override
  State<AdminVenueDetailPage> createState() => _AdminVenueDetailPageState();
}

class _AdminVenueDetailPageState extends State<AdminVenueDetailPage> {
  PadelCourt get v => widget.venue;

  Future<void> _decide(String decision) async {
    final done = await runAdminDecision(context, v, decision);
    if (done && mounted) Navigator.pop(context, true);
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    switch (v.status) {
      case 'menunggu':
        actions.addAll([
          Expanded(
            child: OutlinedButton(
              onPressed: () => _decide('ditolak'),
              child: Text('Tolak', style: TextStyle(color: Colors.red.shade600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _decide('disetujui'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: adminColor, foregroundColor: Colors.white),
              child: const Text('Setujui'),
            ),
          ),
        ]);
        break;
      case 'disetujui':
        actions.add(Expanded(
          child: OutlinedButton(
            onPressed: () => _decide('ditangguhkan'),
            child: Text('Tangguhkan tempat',
                style: TextStyle(color: Colors.red.shade600)),
          ),
        ));
        break;
      default: // ditolak / ditangguhkan
        actions.add(Expanded(
          child: ElevatedButton(
            onPressed: () => _decide('disetujui'),
            style: ElevatedButton.styleFrom(
                backgroundColor: adminColor, foregroundColor: Colors.white),
            child: Text(v.status == 'ditolak' ? 'Setujui' : 'Aktifkan kembali'),
          ),
        ));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: adminColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Detail Tempat',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: actions),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      v.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.sports_tennis, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(v.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    VenueStatusChip(status: v.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StarRating(rating: v.rating),
                    const SizedBox(width: 6),
                    Text(
                      v.reviewCount == 0
                          ? 'Belum ada ulasan'
                          : '${v.rating} dari ${v.reviewCount} ulasan',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (v.rejectReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Alasan: ${v.rejectReason}',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                  ),
                ],
                _title('Informasi'),
                _row(Icons.category_outlined,
                    '${v.category} • ${v.isIndoor ? 'Indoor' : 'Outdoor'}${v.isClass ? '' : ' • ${v.fieldCount} lapangan'}'),
                _row(Icons.payments_outlined, '${formatRupiah(v.pricePerHour)} / jam'),
                if (!v.isClass) _row(Icons.schedule, v.openHours),
                _row(Icons.place_outlined, v.location),
                if (v.hasCoordinates)
                  _row(Icons.my_location, '${v.latitude}, ${v.longitude}'),
                if (v.whatsapp.isNotEmpty) _row(Icons.chat_outlined, v.whatsapp),
                if (v.mapsUrl.isNotEmpty) _row(Icons.map_outlined, v.mapsUrl),
                _title('Pengaju'),
                _row(Icons.person_outline, v.ownerName.isEmpty ? '(tanpa nama)' : v.ownerName),
                _row(Icons.phone_outlined, v.ownerPhone),
                _row(Icons.email_outlined, v.ownerEmail),
                if (v.createdAt != null)
                  _row(Icons.event_outlined, 'Diajukan ${formatShortDate(v.createdAt!)}'),
                _title('Deskripsi'),
                Text(v.description, style: const TextStyle(fontSize: 13, height: 1.5)),
                if (v.facilities.isNotEmpty) ...[
                  _title('Fasilitas'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: v.facilities.map((f) => FacilityChip(label: f)).toList(),
                  ),
                ],
                _title('Ulasan pengguna'),
                ReviewsSection(venueId: v.id, limit: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}