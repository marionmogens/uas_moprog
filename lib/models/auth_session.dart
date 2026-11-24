// Sesi login dari Supabase Auth: token akses (berumur pendek, +- 1 jam)
// dan token refresh (untuk meminta token akses baru tanpa login ulang).
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  // Dianggap kedaluwarsa 30 detik lebih awal sebagai pengaman.
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 30)));

  // Dari respons Supabase Auth (signup / login / refresh token).
  factory AuthSession.fromAuthResponse(Map<String, dynamic> json) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      userId: user['id'] as String,
    );
  }

  // Dari / ke SharedPreferences.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires_at'] as int),
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.millisecondsSinceEpoch,
    'user_id': userId,
  };
}