import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../widgets/reviews_section.dart';
import '../../widgets/star_rating.dart';
import 'admin_actions.dart';

class AdminReviewsTab extends StatefulWidget {
  final List<Review> reviews;
  final Future<void> Function() onRefresh;
  const AdminReviewsTab({super.key, required this.reviews, required this.onRefresh});

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> {
  int? _stars; // null = semua

  @override
  Widget build(BuildContext context) {
    final all = widget.reviews;
    final shown = _stars == null ? all : all.where((r) => r.rating == _stars).toList();
    final avg = all.isEmpty ? 0.0 : all.fold<int>(0, (s, r) => s + r.rating) / all.length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(all.isEmpty ? '-' : avg.toStringAsFixed(1),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 34, color: adminColor)),
                    StarRating(rating: avg, size: 16),
                    const SizedBox(height: 2),
                    Text('${all.length} ulasan',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (var s = 5; s >= 1; s--) _bar(s, all),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Semua', null),
                for (var s = 5; s >= 1; s--) _chip('$s ★', s),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada ulasan')),
            ),
          for (final r in shown) ReviewTile(review: r, showVenue: true),
        ],
      ),
    );
  }

  Widget _chip(String label, int? value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _stars == value,
      selectedColor: adminColor.withOpacity(0.18),
      onSelected: (_) => setState(() => _stars = value),
    ),
  );

  Widget _bar(int stars, List<Review> all) {
    final count = all.where((r) => r.rating == stars).length;
    final fraction = all.isEmpty ? 0.0 : count / all.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 14, child: Text('$stars', style: const TextStyle(fontSize: 11))),
          const Icon(Icons.star, size: 11, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            child: Text('$count',
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}