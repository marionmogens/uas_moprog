import 'padel_court.dart';

enum BookingPhase { upcoming, inProgress, finished, cancelled, rejected }

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
  final int refundAmount; // diisi server saat dibatalkan (50% dari total)

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
    this.refundAmount = 0,
  });

  // ---- Fase reservasi (dihitung dari tanggal + jam slot) ----
  // Slot ke-0 = jam 06:00, tiap slot 1 jam. Jadwal selesai di akhir slot terakhir.
  bool get isCancelledOrRejected =>
      status == statusCancelled || status == statusRejected;

  int get _firstSlot =>
      slotIndexes.isEmpty ? 0 : slotIndexes.reduce((a, b) => a < b ? a : b);
  int get _lastSlot =>
      slotIndexes.isEmpty ? 0 : slotIndexes.reduce((a, b) => a > b ? a : b);

  DateTime get startTime => DateTime(bookingDate.year, bookingDate.month,
      bookingDate.day, PadelCourt.firstSlotHour + _firstSlot);
  DateTime get endTime => DateTime(bookingDate.year, bookingDate.month,
      bookingDate.day, PadelCourt.firstSlotHour + _lastSlot + 1);

  BookingPhase get phase {
    if (status == statusCancelled) return BookingPhase.cancelled;
    if (status == statusRejected) return BookingPhase.rejected;
    final now = DateTime.now();
    if (!endTime.isAfter(now)) return BookingPhase.finished;
    if (!startTime.isAfter(now)) return BookingPhase.inProgress;
    return BookingPhase.upcoming;
  }

  // Tab "Aktif" = belum selesai; tab "Riwayat" = selesai / dibatalkan / ditolak.
  bool get isActive =>
      phase == BookingPhase.upcoming || phase == BookingPhase.inProgress;
  bool get isFinished => phase == BookingPhase.finished;

  // Batal hanya sampai H-1 (tidak bisa di hari-H). Refund 50%.
  // Ulasan hanya setelah jadwal selesai.
  bool get canCancel {
    if (status != statusPending && status != statusConfirmed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return bookingDate.isAfter(today);
  }

  bool get canReview => isFinished;

  String get displayLabel {
    switch (phase) {
      case BookingPhase.upcoming:
        return status == statusPending ? 'Menunggu konfirmasi' : 'Akan datang';
      case BookingPhase.inProgress:
        return 'Sedang berlangsung';
      case BookingPhase.finished:
        return 'Selesai';
      case BookingPhase.cancelled:
        return 'Dibatalkan';
      case BookingPhase.rejected:
        return 'Ditolak';
    }
  }

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
      refundAmount: (json['refund_amount'] as num?)?.toInt() ?? 0,
    );
  }
}