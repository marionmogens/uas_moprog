import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../utils/formatters.dart';
import 'star_rating.dart';

class ReviewsSection extends StatelessWidget {
  final String venueId;
  final int limit;
  const ReviewsSection({super.key, required this.venueId, this.limit = 5});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: ReviewService.instance.fetchForVenue(venueId, limit: limit),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          return Text('Ulasan belum bisa dimuat.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
        }
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) {
          return Text('Belum ada ulasan.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
        }
        return Column(
          children: reviews.map((r) => ReviewTile(review: r)).toList(),
        );
      },
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;
  final bool showVenue;
  // Diisi hanya di tampilan pemilik tempat: menampilkan tombol hapus.
  final VoidCallback? onDelete;
  const ReviewTile({
    super.key,
    required this.review,
    this.showVenue = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showVenue && review.venueName.isNotEmpty) ...[
            Text(review.venueName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              StarRating(rating: review.rating.toDouble()),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${review.userName} • ${formatShortDate(review.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Hapus ulasan',
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.red.shade400),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment, style: const TextStyle(fontSize: 12.5, height: 1.4)),
          ],
        ],
      ),
    );
  }
}