import 'padel_court.dart';

enum VenueSort { recommended, nearest, cheapest, topRated }

extension VenueSortLabel on VenueSort {
  String get label {
    switch (this) {
      case VenueSort.nearest:
        return 'Terdekat';
      case VenueSort.cheapest:
        return 'Termurah';
      case VenueSort.topRated:
        return 'Rating tertinggi';
      default:
        return 'Rekomendasi';
    }
  }
}

class VenueFilter {
  static const int budgetMin = 0;
  static const int budgetMax = 500000; // 500000 = "500 rb ke atas"
  static const int budgetStep = 25000;
  static const List<double> radiusOptions = [3, 5, 10, 20];

  final String? city;
  final int minPrice;
  final int maxPrice;
  final double? radiusKm;
  final bool? indoor;
  final VenueSort sort;

  const VenueFilter({
    this.city,
    this.minPrice = budgetMin,
    this.maxPrice = budgetMax,
    this.radiusKm,
    this.indoor,
    this.sort = VenueSort.recommended,
  });

  bool get hasBudget => minPrice > budgetMin || maxPrice < budgetMax;

  int get activeCount =>
      (city != null ? 1 : 0) +
          (hasBudget ? 1 : 0) +
          (radiusKm != null ? 1 : 0) +
          (indoor != null ? 1 : 0) +
          (sort != VenueSort.recommended ? 1 : 0);

  VenueFilter copyWith({
    String? city,
    bool clearCity = false,
    int? minPrice,
    int? maxPrice,
    double? radiusKm,
    bool clearRadius = false,
    bool? indoor,
    bool clearIndoor = false,
    VenueSort? sort,
  }) {
    return VenueFilter(
      city: clearCity ? null : (city ?? this.city),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
      indoor: clearIndoor ? null : (indoor ?? this.indoor),
      sort: sort ?? this.sort,
    );
  }

  List<PadelCourt> apply(
      List<PadelCourt> source, {
        required String category,
        required String query,
      }) {
    final q = query.trim().toLowerCase();
    final result = source.where((c) {
      if (c.category != category) return false;
      if (q.isNotEmpty &&
          !(c.name.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q))) {
        return false;
      }
      if (city != null && c.city != city) return false;
      if (c.pricePerHour < minPrice) return false;
      if (maxPrice < budgetMax && c.pricePerHour > maxPrice) return false;
      if (indoor != null && c.isIndoor != indoor) return false;
      if (radiusKm != null) {
        final d = c.distanceKm;
        if (d == null || d > radiusKm!) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case VenueSort.nearest:
        result.sort((a, b) {
          final da = a.distanceKm;
          final db = b.distanceKm;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
      case VenueSort.cheapest:
        result.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case VenueSort.topRated:
        result.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
        });
        break;
      case VenueSort.recommended:
        break;
    }
    return result;
  }
}