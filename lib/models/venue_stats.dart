// Satu baris hasil fungsi SQL venue_booking_stats (ringkasan per tempat).
class VenueStats {
  final String venueId;
  final String venueName;
  final String category;
  final String city;
  final String status;
  final int totalBookings; // tidak termasuk yang dibatalkan/ditolak
  final int cancelledBookings;
  final int revenue; // total harga pesanan yang tidak dibatalkan (Rp)

  const VenueStats({
    required this.venueId,
    required this.venueName,
    required this.category,
    required this.city,
    required this.status,
    required this.totalBookings,
    required this.cancelledBookings,
    required this.revenue,
  });

  factory VenueStats.fromJson(Map<String, dynamic> json) {
    return VenueStats(
      venueId: json['venue_id'] as String,
      venueName: (json['venue_name'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      cancelledBookings: (json['cancelled_bookings'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
    );
  }
}