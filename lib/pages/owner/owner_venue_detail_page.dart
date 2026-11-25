import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../models/review.dart';
import '../../services/api_exception.dart';
import '../../services/review_service.dart';
import '../../services/venue_service.dart';
import '../../utils/formatters.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/facility_chip.dart';
import '../../widgets/reviews_section.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/status_chip.dart';
import 'venue_form_page.dart';

class OwnerVenueDetailPage extends StatefulWidget {
  final PadelCourt venue;
  const OwnerVenueDetailPage({super.key, required this.venue});

  @override
  State<OwnerVenueDetailPage> createState() => _OwnerVenueDetailPageState();
}

class _OwnerVenueDetailPageState extends State<OwnerVenueDetailPage> {
  late bool _accepting;
  bool _busy = false;
  int? _stars; // null = semua ulasan
  late Future<List<Review>> _reviews;

  PadelCourt get v => widget.venue;
  Color get _accent => Colors.pink.shade300;

  @override
  void initState() {
    super.initState();
    _accepting = v.isAvailable;
    _loadReviews();
  }

  void _loadReviews() {
    _reviews = ReviewService.instance.fetchForVenue(v.id, limit: 200);
  }

  Future<void> _toggle(bool on) async {
    setState(() {
      _busy = true;
      _accepting = on;
    });
    try {
      await VenueService.instance.setAccepting(v.id, on);
      if (!mounted) return;
      showMessage(context,
          on ? 'Tempat kembali menerima pesanan' : 'Tempat tidak menerima pesanan');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _accepting = !on);
      showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VenueFormPage(existing: v)),
    );
    if (saved == true && mounted) {
      showMessage(context, 'Perubahan disimpan');
      Navigator.pop(context); // daftar Kelola Lapangan akan memuat ulang
    }
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
    child: Text(t,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _accent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(v.isClass ? 'Detail Kelas' : 'Detail Lapangan',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(v.isClass ? 'Ubah Data Kelas' : 'Ubah Data Lapangan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
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
                        child: const Icon(Icons.sports_tennis,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(v.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
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
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (v.rejectReason.isNotEmpty &&
                    (v.status == 'ditolak' || v.status == 'ditangguhkan')) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Alasan admin: ${v.rejectReason}',
                        style:
                        TextStyle(fontSize: 12, color: Colors.red.shade700)),
                  ),
                ],
                if (v.status == 'disetujui')
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      value: _accepting,
                      onChanged: _busy ? null : _toggle,
                      activeColor: _accent,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Menerima pesanan',
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text(
                        _accepting
                            ? 'Aktif: pelanggan bisa memesan'
                            : 'Nonaktif: tampil "Penuh" di Beranda',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                _title('Informasi'),
                _row(Icons.category_outlined,
                    '${v.category} • ${v.isIndoor ? 'Indoor' : 'Outdoor'}${v.isClass ? '' : ' • ${v.fieldCount} lapangan'}'),
                _row(Icons.payments_outlined,
                    '${formatRupiah(v.pricePerHour)} / jam'),
                if (!v.isClass) _row(Icons.schedule, v.openHours),
                _row(Icons.place_outlined, v.location),
                if (v.whatsapp.isNotEmpty) _row(Icons.chat_outlined, v.whatsapp),
                if (v.mapsUrl.isNotEmpty) _row(Icons.map_outlined, v.mapsUrl),
                if (v.description.isNotEmpty) ...[
                  _title('Deskripsi'),
                  Text(v.description,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
                if (v.facilities.isNotEmpty) ...[
                  _title('Fasilitas'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                    v.facilities.map((f) => FacilityChip(label: f)).toList(),
                  ),
                ],
                _title('Rating & ulasan'),
                _buildReviews(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviews() {
    return FutureBuilder<List<Review>>(
      future: _reviews,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          return Row(
            children: [
              Expanded(
                child: Text('Ulasan belum bisa dimuat.',
                    style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
              TextButton(
                onPressed: () => setState(_loadReviews),
                child: const Text('Coba lagi'),
              ),
            ],
          );
        }
        final all = snap.data ?? [];
        if (all.isEmpty) {
          return Text('Belum ada ulasan.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
        }
        final shown =
        _stars == null ? all : all.where((r) => r.rating == _stars).toList();
        final avg =
            all.fold<int>(0, (s, r) => s + r.rating) / all.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(avg.toStringAsFixed(1),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 34,
                              color: _accent)),
                      StarRating(rating: avg, size: 16),
                      const SizedBox(height: 2),
                      Text('${all.length} ulasan',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        for (var s = 5; s >= 1; s--) _bar(s, all),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Semua', null),
                  for (var s = 5; s >= 1; s--) _chip('$s ★', s),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('Tidak ada ulasan $_stars ★',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ),
              ),
            for (final r in shown) ReviewTile(review: r),
          ],
        );
      },
    );
  }

  Widget _chip(String label, int? value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _stars == value,
      selectedColor: _accent.withOpacity(0.25),
      onSelected: (_) => setState(() => _stars = value),
    ),
  );

  Widget _bar(int stars, List<Review> all) {
    final count = all.where((r) => r.rating == stars).length;
    final fraction = all.isEmpty ? 0.0 : count / all.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 14,
              child: Text('$stars', style: const TextStyle(fontSize: 11))),
          const Icon(Icons.star, size: 11, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}