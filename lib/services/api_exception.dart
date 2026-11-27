// Error yang sudah "ramah pengguna": pesannya langsung bisa ditampilkan
// di SnackBar. isNetwork = true artinya masalah koneksi/timeout
// (bukan salah input), supaya UI bisa menawarkan "Coba lagi".
// code = kode error dari server (mis. 'email_not_confirmed'), dipakai UI
// untuk mengambil tindakan khusus tanpa membaca teks pesan.
class ApiException implements Exception {
  static const String emailNotConfirmed = 'email_not_confirmed';

  final String message;
  final int? statusCode;
  final bool isNetwork;
  final String? code;

  const ApiException(this.message,
      {this.statusCode, this.isNetwork = false, this.code});

  @override
  String toString() => message;
}