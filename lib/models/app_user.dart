// Model profil pengguna (satu baris di tabel `profiles`).
//   pelanggan : akun biasa (bisa memesan, dan mengajukan tempat dari tab Akun)
//   pemilik   : pelanggan yang pengajuan tempatnya sudah disetujui admin
//   admin     : mengelola persetujuan (diatur manual lewat SQL, bukan dari aplikasi)
class AppUser {
  static const String roleCustomer = 'pelanggan';
  static const String roleOwner = 'pemilik';
  static const String roleAdmin = 'admin';

  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  bool get isOwner => role == roleOwner;
  bool get isAdmin => role == roleAdmin;

  String get roleLabel {
    switch (role) {
      case roleAdmin:
        return 'Admin';
      case roleOwner:
        return 'Pemilik Tempat';
      default:
        return 'Pelanggan';
    }
  }

  // Huruf pertama nama, untuk avatar.
  String get initial =>
      fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: (json['email'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      role: (json['role'] ?? roleCustomer) as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'role': role,
  };
}