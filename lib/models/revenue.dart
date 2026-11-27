import '../config/revenue_config.dart';

// Pendapatan satu tempat: jumlah pesanan berbayar dan total (kotor) uangnya.
class VenueRevenue {
  final String venueId;
  final String venueName;
  final String ownerName;
  final int bookingCount;
  final int gross; // total pendapatan sebelum dibagi

  const VenueRevenue({
    required this.venueId,
    required this.venueName,
    required this.ownerName,
    required this.bookingCount,
    required this.gross,
  });

  int get platformShare => RevenueConfig.platformShare(gross); // 20% admin
  int get ownerShare => RevenueConfig.ownerShare(gross); // 80% pemilik

  factory VenueRevenue.fromJson(Map<String, dynamic> json) {
    return VenueRevenue(
      venueId: (json['venue_id'] ?? '') as String,
      venueName: (json['venue_name'] ?? '') as String,
      ownerName: (json['owner_name'] ?? '-') as String,
      bookingCount: (json['booking_count'] as num?)?.toInt() ?? 0,
      gross: (json['gross'] as num?)?.toInt() ?? 0,
    );
  }
}

// Gabungan pendapatan semua tempat yang boleh dilihat pengguna ini
// (admin: semua tempat, pemilik: tempat miliknya saja).
class RevenueSummary {
  final List<VenueRevenue> venues;
  const RevenueSummary(this.venues);

  int get totalGross => venues.fold(0, (s, v) => s + v.gross);
  int get totalBookings => venues.fold(0, (s, v) => s + v.bookingCount);
  int get platformShare => venues.fold(0, (s, v) => s + v.platformShare);
  int get ownerShare => totalGross - platformShare;

  Map<String, VenueRevenue> get byVenue => {for (final v in venues) v.venueId: v};
}