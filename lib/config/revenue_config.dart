// Pembagian pendapatan. Ubah angka di sini kalau persentasenya berubah.
// Admin (platform) mendapat komisi 20% dari tiap pesanan berbayar,
// sisanya 80% menjadi pendapatan bersih pemilik tempat.
class RevenueConfig {
  RevenueConfig._();

  static const int platformPercent = 20;
  static const int ownerPercent = 100 - platformPercent;

  static int platformShare(int gross) => gross * platformPercent ~/ 100;
  static int ownerShare(int gross) => gross - platformShare(gross);
}