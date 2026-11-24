class BookingAddon {
  final String name;
  final int price;
  final int quantity;

  const BookingAddon({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory BookingAddon.fromJson(Map<String, dynamic> json) {
    return BookingAddon(
      name: (json['name'] ?? '') as String,
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class Booking {
  // Pembayaran di aplikasi bersifat simulasi dan langsung sukses, jadi
  // pesanan baru langsung berstatus `dikonfirmasi` (ditampilkan sebagai
  // "Pembayaran Berhasil"). Nilai lain dipertahankan agar data lama tetap
  // terbaca.
  static const String statusPending = 'menunggu';
  static const String statusConfirmed = 'dikonfirmasi';
  static const String statusRejected = 'ditolak';
  static const String statusCancelled = 'dibatalkan';

  final String id;
  final String bookingCode;
  final String courtId;
  final String courtName;
  final String fieldName;
  final DateTime bookingDate;
  final List<int> slotIndexes;
  final String timeSlot;
  final String duration;
  final int courtPrice;
  final List<BookingAddon> addons;
  final String note;
  final int totalPrice;
  final String customerName;
  final String customerPhone;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.bookingCode,
    required this.courtId,
    required this.courtName,
    required this.fieldName,
    required this.bookingDate,
    required this.slotIndexes,
    required this.timeSlot,
    required this.duration,
    required this.courtPrice,
    required this.addons,
    required this.note,
    required this.totalPrice,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  bool get canReview => status != statusCancelled && status != statusRejected;

  String get statusLabel {
    switch (status) {
      case statusRejected:
        return 'Ditolak';
      case statusCancelled:
        return 'Dibatalkan';
      default:
      // dikonfirmasi (dan data lama berstatus menunggu) = sudah dibayar.
        return 'Pembayaran Berhasil';
    }
  }

  String get addonsText =>
      addons.map((a) => '${a.name} x${a.quantity}').join(', ');

  factory Booking.fromJson(Map<String, dynamic> json) {
    final slots = (json['slot_indexes'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final addons = (json['addons'] as List<dynamic>? ?? [])
        .map((e) => BookingAddon.fromJson(e as Map<String, dynamic>))
        .toList();
    return Booking(
      id: json['id'] as String,
      bookingCode: (json['booking_code'] ?? '') as String,
      courtId: (json['court_id'] ?? '') as String,
      courtName: (json['court_name'] ?? '') as String,
      fieldName: (json['field_name'] ?? '') as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      slotIndexes: slots,
      timeSlot: (json['time_slot'] ?? '') as String,
      duration: (json['duration'] ?? '') as String,
      courtPrice: (json['court_price'] as num?)?.toInt() ?? 0,
      addons: addons,
      note: (json['note'] ?? '') as String,
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      customerName: (json['customer_name'] ?? '') as String,
      customerPhone: (json['customer_phone'] ?? '') as String,
      paymentMethod: (json['payment_method'] ?? '') as String,
      status: (json['status'] ?? statusConfirmed) as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}