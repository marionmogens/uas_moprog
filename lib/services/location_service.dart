import 'package:geolocator/geolocator.dart';

class UserLocation {
  final double latitude;
  final double longitude;
  const UserLocation(this.latitude, this.longitude);
}

class LocationException implements Exception {
  final String message;
  final bool openAppSettings;
  final bool openLocationSettings;
  const LocationException(this.message,
      {this.openAppSettings = false, this.openLocationSettings = false});

  @override
  String toString() => message;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  UserLocation? last;

  Future<UserLocation> getCurrent() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'Layanan lokasi di perangkat sedang mati. Aktifkan GPS lalu coba lagi.',
        openLocationSettings: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
          'Izin lokasi ditolak, jadi lapangan terdekat tidak bisa ditampilkan.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi diblokir. Izinkan lokasi lewat pengaturan aplikasi.',
        openAppSettings: true,
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      last = UserLocation(pos.latitude, pos.longitude);
      return last!;
    } catch (_) {
      throw const LocationException(
          'Gagal mendapatkan lokasimu. Coba lagi di tempat yang sinyalnya lebih baik.');
    }
  }

  double distanceKm(UserLocation from, double lat, double lng) {
    return Geolocator.distanceBetween(
        from.latitude, from.longitude, lat, lng) /
        1000;
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}