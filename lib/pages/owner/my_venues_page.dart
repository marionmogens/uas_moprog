import 'package:flutter/material.dart';
import '../../config/revenue_config.dart';
import '../../models/padel_court.dart';
import '../../models/revenue.dart';
import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/revenue_service.dart';
import '../../services/venue_service.dart';
import '../../utils/formatters.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/status_chip.dart';
import 'owner_venue_detail_page.dart';
import 'venue_form_page.dart';

class MyVenuesPage extends StatefulWidget {
  const MyVenuesPage({super.key});

  @override
  State<MyVenuesPage> createState() => _MyVenuesPageState();
}

class _MyVenuesPageState extends State<MyVenuesPage> {
  late Future<List<PadelCourt>> _future;

  // Status on/off yang sudah diubah di layar (langsung terlihat sebelum reload).
  final Map<String, bool> _accepting = {};
  final Set<String> _busy = {};

  // Pendapatan semua tempat milik user ini (null = belum ada / gagal dimuat).
  RevenueSummary? _revenue;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PadelCourt>> _load() async {
    final list = await VenueService.instance.fetchMine();
    await AuthService.instance.refreshProfile();
    try {
      _revenue = await RevenueService.instance.fetch();
    } on ApiException {
      _revenue = null; // pendapatan tidak boleh menghalangi daftar tempat
    }
    return list;
  }

  void _reload() {
    _accepting.clear();
    setState(() => _future = _load());
  }

  Future<void> _openForm([PadelCourt? venue]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VenueFormPage(existing: venue)),
    );
    if (saved == true) {
      if (mounted) {
        showMessage(
            context,
            venue == null
                ? 'Pengajuan terkirim. Menunggu persetujuan admin.'
                : 'Perubahan disimpan');
      }
      _reload();
    }
  }

  Future<void> _openDetail(PadelCourt venue) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OwnerVenueDetailPage(venue: venue)),
    );
    if (mounted) _reload();
  }

  Future<void> _toggleAccepting(PadelCourt v, bool on) async {
    if (_busy.contains(v.id)) return;
    setState(() {
      _busy.add(v.id);
      _accepting[v.id] = on;
    });
    try {
      await VenueService.instance.setAccepting(v.id, on);
      if (!mounted) return;
      showMessage(context,
          on ? 'Tempat kembali menerima pesanan' : 'Tempat tidak menerima pesanan');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _accepting[v.id] = !on);
      showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy.remove(v.id));
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
        title: const Text('Kelola Lapangan',
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
                  OutlinedButton(
                      onPressed: _reload, child: const Text('Coba lagi')),
                ],
              ),
            );
          }
          final venues = snap.data ?? [];
          if (venues.isEmpty) return _buildEmpty();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: venues.length + (_revenue != null ? 1 : 0),
              itemBuilder: (_, i) {
                if (_revenue == null) return _buildCard(venues[i]);
                if (i == 0) return _buildRevenueCard(_revenue!);
                return _buildCard(venues[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }

  // Ringkasan pendapatan di atas daftar: total pendapatan dan bagian bersih
  // pemilik setelah komisi PadelBook dipotong.
  Widget _buildRevenueCard(RevenueSummary r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Pendapatan',
              style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatRupiah(r.totalGross),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26)),
          ),
          Text('${r.totalBookings} pesanan berbayar',
              style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pendapatan Bersih (${RevenueConfig.ownerPercent}%)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(formatRupiah(r.ownerShare),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Komisi PadelBook (${RevenueConfig.platformPercent}%)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(formatRupiah(r.platformShare),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              Icon(Icons.storefront_outlined,
                  size: 64, color: Colors.pink.shade200),
              const SizedBox(height: 12),
              const Text('Punya lapangan padel?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                  'Daftarkan lapangan atau kelasmu dan terima pesanan lewat PadelBook.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),
              step(1, 'Isi data tempat (lokasi, harga, jam, fasilitas, foto).'),
              step(2, 'Admin meninjau pengajuanmu.'),
              step(3,
                  'Setelah disetujui, tempat tampil di Beranda dan kamu menjadi Pemilik Tempat.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Daftarkan Tempat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade300,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(PadelCourt v) {
    final approved = v.status == 'disetujui';
    final accepting = _accepting[v.id] ?? v.isAvailable;
    final rv = _revenue?.byVenue[v.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetail(v),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
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
                            child: const Icon(Icons.sports_tennis,
                                color: Colors.grey),
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
                          Text(
                              '${v.category} • ${v.city} • ${formatRupiah(v.pricePerHour)}/jam',
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          VenueStatusChip(status: v.status),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 22, color: Colors.grey.shade500),
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
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade700)),
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
                  if (rv != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 15, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Pendapatan ${formatRupiah(rv.gross)} • '
                                'Bersih ${formatRupiah(rv.ownerShare)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SwitchListTile(
                    value: accepting,
                    onChanged: _busy.contains(v.id)
                        ? null
                        : (on) => _toggleAccepting(v, on),
                    activeColor: Colors.pink.shade300,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Menerima pesanan',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      accepting
                          ? 'Aktif: pelanggan bisa memesan'
                          : 'Nonaktif: tampil "Penuh" di Beranda',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openForm(v),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Ubah'),
                    ),
                    if (v.status == 'ditolak')
                      ElevatedButton(
                        onPressed: () => _run(
                                () => VenueService.instance.resubmit(v.id),
                            'Diajukan ulang ke admin'),
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
          ),
        ),
      ),
    );
  }
}