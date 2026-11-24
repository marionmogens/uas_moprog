class Review {
  final String id;
  final String venueId;
  final String venueName;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String,
      venueId: (json['venue_id'] ?? '') as String,
      venueName: venue == null ? '' : (venue['name'] ?? '') as String,
      userName: (json['user_name'] ?? 'Pengguna') as String,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}