import 'package:flutter/material.dart';
import '../data/booking_options.dart';
import '../models/booking_draft.dart';
import '../models/padel_court.dart';
import '../utils/formatters.dart';
import '../widgets/facility_chip.dart';
import '../widgets/selectable_option.dart';
import 'schedule_page.dart';
import '../widgets/reviews_section.dart';
import '../utils/guest_gate.dart';

class DetailPage extends StatefulWidget {
  final PadelCourt court;
  const DetailPage({super.key, required this.court});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // index durasi terpilih (default: durasi pertama, 1 Jam)
  int _selectedDurationIndex = 0;

  // nama add-on yang sedang dipilih (bisa lebih dari satu)
  final Set<String> _selectedAddons = {};

  final TextEditingController _noteController = TextEditingController();

  // Jumlah tiap add-on yang dipilih (default 1, diatur lewat tombol + / -).
  final Map<String, int> _addonQuantities = {};

  @override
  void initState() {
    super.initState();
    // Kelas selalu 2 jam, jadi durasinya tidak dipilih pengguna.
    if (widget.court.category == 'Kelas') {
      final twoHours = durationOptions.indexWhere((d) => d.label == '2 Jam');
      if (twoHours != -1) _selectedDurationIndex = twoHours;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    // Tamu tidak bisa menyimpan favorit -> diarahkan ke Login / Daftar.
    if (!requireLogin(context,
        message: 'Masuk atau daftar dulu untuk menyimpan favorit.')) {
      return;
    }
    setState(() {
      widget.court.isFavorite = !widget.court.isFavorite;
    });
  }

  void _onImageLongPress() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            widget.court.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.sports_tennis,
                  color: Colors.grey, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  // Getter _addons
  List<AddonOption> get _addons => addonsFor(widget.court.category);

  // Total harga dihitung ulang setiap build() dipanggil -> karena
  // dipanggil dari dalam setState (lewat pilih durasi/add-on), hasilnya
  // selalu "realtime" mengikuti state terbaru tanpa perlu logic tambahan.
  int get _totalPrice {
    final duration = durationOptions[_selectedDurationIndex];
    final base = (widget.court.pricePerHour * duration.multiplier).round();
    final addonsPrice = _addons
        .where((addon) => _selectedAddons.contains(addon.name))
        .fold(0, (sum, addon) => sum + addon.price * (_addonQuantities[addon.name] ?? 1));
    return base + addonsPrice;
  }

  // Harga sewa lapangan saja (tanpa add-on) untuk durasi yang dipilih.
  int get _courtPrice {
    final duration = durationOptions[_selectedDurationIndex];
    return (widget.court.pricePerHour * duration.multiplier).round();
  }

  void _goToSchedule() {
    // Tamu tidak bisa memesan -> diarahkan ke Login / Daftar.
    if (!requireLogin(context,
        message: 'Masuk atau daftar dulu untuk memesan lapangan atau kelas.')) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchedulePage(
          court: widget.court,
          duration: durationOptions[_selectedDurationIndex].label,
          durationHours: durationOptions[_selectedDurationIndex].hours,
          addons: _addons
              .where((addon) => _selectedAddons.contains(addon.name))
              .map((addon) => DraftAddon(
            name: addon.name,
            price: addon.price,
            quantity: _addonQuantities[addon.name] ?? 1,
          ))
              .toList(),
          note: _noteController.text.trim(),
          courtPrice: _courtPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final court = widget.court;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        title: Text(court.name,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              court.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: court.isFavorite ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(court),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderInfo(court),
                    const Divider(height: 28),
                    const _SectionTitle('Tentang Lapangan'),
                    const SizedBox(height: 6),
                    Text(
                      court.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Fasilitas'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: court.facilities
                          .map((facility) => FacilityChip(label: facility))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(court.reviewCount == 0
                        ? 'Ulasan'
                        : 'Ulasan (${court.reviewCount})'),
                    const SizedBox(height: 10),
                    ReviewsSection(venueId: court.id),
                    if (widget.court.category != 'Kelas') ...[
                      const SizedBox(height: 20),
                      const _SectionTitle('Pilih Durasi'),
                      const SizedBox(height: 10),
                      _buildDurationPicker(),
                    ],
                    const SizedBox(height: 20),
                    const _SectionTitle('Tambahan (Opsional)'),
                    if (widget.court.category == 'Kelas') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sudah termasuk pelatih, raket dan bola untuk 2 orang. '
                            'Silakan menambah raket atau bola apabila diperlukan.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildAddonPicker(),
                    const SizedBox(height: 20),
                    const _SectionTitle('Catatan untuk Penyedia'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Contoh: tolong siapkan net cadangan',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(top: false, child: _buildBottomBar(court)),
    );
  }

  Widget _buildImage(PadelCourt court) {
    // Stack: gambar lapangan + label status ("Tersedia"/"Penuh") di atasnya
    return GestureDetector(
      onDoubleTap: _toggleFavorite,
      onLongPress: _onImageLongPress,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              court.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.sports_tennis,
                    color: Colors.grey, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: court.isAvailable ? Colors.green : Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                court.isAvailable ? 'Tersedia' : 'Penuh',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(PadelCourt court) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          court.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                court.location,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(court.reviewCount == 0 ? 'Baru' : '${court.rating}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text(court.reviewCount == 0 ? '(belum ada ulasan)' : '(${court.reviewCount} ulasan)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              court.category == 'Kelas'
                  ? '${formatRupiah(court.pricePerHour)}/jam • Durasi 2 jam per sesi'
                  : '${formatRupiah(court.pricePerHour)}/jam',
              style: TextStyle(
                color: Colors.pink.shade300,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              court.isIndoor ? Icons.home_work_outlined : Icons.park_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              court.isIndoor ? 'Indoor' : 'Outdoor',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // Pilihan durasi dalam bentuk Row dari SelectableOption. Pakai
  // Expanded supaya ketiga pilihan melebar rata, bukan lebar seadanya.
  Widget _buildDurationPicker() {
    return Row(
      children: List.generate(durationOptions.length, (index) {
        final option = durationOptions[index];
        final isSelected = _selectedDurationIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == durationOptions.length - 1 ? 0 : 8,
            ),
            child: SelectableOption(
              selected: isSelected,
              onTap: () => setState(() => _selectedDurationIndex = index),
              child: Text(
                option.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? Colors.pink.shade300 : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Pilihan add-on: multi-select, pakai Wrap supaya tidak overflow
  // kalau layar sempit atau nama add-on panjang. Add-on yang dipilih
  // muncul di bawahnya dengan tombol + / - untuk mengatur jumlah.
  Widget _buildAddonPicker() {
    final selected =
    _addons.where((a) => _selectedAddons.contains(a.name)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _addons.map((addon) {
            final isSelected = _selectedAddons.contains(addon.name);
            return SelectableOption(
              selected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAddons.remove(addon.name);
                    _addonQuantities.remove(addon.name);
                  } else {
                    _selectedAddons.add(addon.name);
                    _addonQuantities[addon.name] = 1;
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.add_circle_outline,
                    size: 16,
                    color: isSelected ? Colors.pink.shade300 : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${addon.name} (+${formatRupiah(addon.price)})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (final addon in selected) ...[
                  _buildAddonQuantityRow(addon),
                  if (addon != selected.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddonQuantityRow(AddonOption addon) {
    final qty = _addonQuantities[addon.name] ?? 1;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(addon.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text(
                '${formatRupiah(addon.price)} x $qty = '
                    '${formatRupiah(addon.price * qty)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        _stepperButton(
          icon: qty == 1 ? Icons.delete_outline : Icons.remove,
          background: Colors.white,
          iconColor: qty == 1 ? Colors.redAccent : Colors.black87,
          onTap: () => setState(() {
            if (qty > 1) {
              _addonQuantities[addon.name] = qty - 1;
            } else {
              _selectedAddons.remove(addon.name);
              _addonQuantities.remove(addon.name);
            }
          }),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        _stepperButton(
          icon: Icons.add,
          background: Colors.pink.shade300,
          iconColor: Colors.white,
          onTap: () => setState(() => _addonQuantities[addon.name] = qty + 1),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }

  Widget _buildBottomBar(PadelCourt court) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total',
                    style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                // _totalPrice recomputed tiap build -> langsung berubah
                // begitu user pilih durasi/add-on berbeda (realtime).
                Text(
                  formatRupiah(_totalPrice),
                  style: TextStyle(
                    color: Colors.pink.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: court.isAvailable ? _goToSchedule : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade300,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(court.isAvailable ? 'Pilih Jadwal' : 'Tidak Tersedia'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }
}