// Error yang sudah "ramah pengguna": pesannya langsung bisa ditampilkan
// di SnackBar. isNetwork = true artinya masalah koneksi/timeout
// (bukan salah input), supaya UI bisa menawarkan "Coba lagi".
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetwork;

  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  @override
  String toString() => message;
}