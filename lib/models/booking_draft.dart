import 'padel_court.dart';

// Satu tambahan (add-on) di dalam reservasi, misal "Sewa Raket" x2.
// Jumlahnya (quantity) diatur lewat tombol + / - di halaman Detail.
class DraftAddon {
  final String name;
  final int price; // harga satuan
  int quantity;

  DraftAddon({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  int get subtotal => price * quantity;

  // Salinan baru, supaya jumlah di satu reservasi tidak ikut
  // berubah di reservasi lain.
  DraftAddon copy() {
    return DraftAddon(name: name, price: price, quantity: quantity);
  }
}

// Satu pesanan yang sedang disiapkan (belum dibayar): sudah lengkap dengan
// durasi, tambahan, catatan, dan jadwal. Dikirim langsung dari halaman
// Jadwal -> Ringkasan -> Pembayaran -> Konfirmasi (tanpa keranjang).
class BookingDraft {
  final String id;
  final PadelCourt court;
  final String fieldName; // "Lapangan 1", "Lapangan 2", dst
  final DateTime date;
  final String timeSlot; // misal "18:00 - 20:00"
  // Index slot jam yang dipesan (posisi di timeSlots).
  final List<int> slotIndexes;
  final String duration; // misal "1 Jam"
  final int courtPrice; // harga sewa lapangan untuk durasi ini (tanpa add-on)
  final List<DraftAddon> addons;
  final String note; // catatan untuk penyedia

  BookingDraft({
    required this.id,
    required this.court,
    required this.fieldName,
    required this.date,
    required this.timeSlot,
    required this.slotIndexes,
    required this.duration,
    required this.courtPrice,
    required this.addons,
    required this.note,
  });

  int get addonsTotal => addons.fold(0, (sum, a) => sum + a.subtotal);

  int get totalPrice => courtPrice + addonsTotal;

  // Teks ringkas untuk Ringkasan / Konfirmasi, misal "Sewa Raket x2, Sewa Bola x1".
  String get addonsText =>
      addons.map((a) => '${a.name} x${a.quantity}').join(', ');
}