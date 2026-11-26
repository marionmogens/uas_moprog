import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/booking.dart';
import '../models/booking_draft.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import '../models/venue_stats.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  static const String classFieldKey = 'Kelas';
  final AuthService _auth = AuthService.instance;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidToken();
    return _auth.authHeaders(token);
  }

  String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Reservasi milik user yang sedang login. Filter user_id WAJIB: pemilik &
  // admin punya akses baca ke pesanan orang lain, jangan ikut tampil di Riwayat.
  Future<List<Booking>> fetchMyBookings() async {
    final headers = await _headers();
    final uid = _auth.currentUser!.id;
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/bookings?user_id=eq.$uid&select=*&order=booking_date.desc,created_at.desc'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((row) => Booking.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // Semua pesanan di satu tempat (untuk pemilik tempat itu & admin).
  Future<List<Booking>> fetchForVenue(
      String venueId, {
        DateTime? from,
        DateTime? to,
      }) async {
    final headers = await _headers();
    final query = StringBuffer(
        'court_id=eq.$venueId&select=*&order=booking_date.desc,created_at.desc&limit=500');
    if (from != null) query.write('&booking_date=gte.${_dateOnly(from)}');
    if (to != null) query.write('&booking_date=lte.${_dateOnly(to)}');
    final res = await ApiClient.send(() => http.get(
      Uri.parse('${SupabaseConfig.restUrl}/bookings?$query'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((row) => Booking.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // Ringkasan total pesanan & pendapatan per tempat.
  // Pemilik: hanya tempatnya. Admin: semua tempat.
  Future<List<VenueStats>> fetchVenueStats({DateTime? from, DateTime? to}) async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/rpc/venue_booking_stats'),
      headers: headers,
      body: jsonEncode({
        'p_from': from == null ? null : _dateOnly(from),
        'p_to': to == null ? null : _dateOnly(to),
      }),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((row) => VenueStats.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Set<int>> fetchTakenSlots({
    required String courtId,
    required String fieldName,
    required DateTime date,
  }) async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/rpc/get_taken_slots'),
      headers: headers,
      body: jsonEncode({
        'p_court_id': courtId,
        'p_field': fieldName,
        'p_date': _dateOnly(date),
      }),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((row) => ((row as Map<String, dynamic>)['slot_index'] as num).toInt())
        .toSet();
  }

  Future<void> createBooking({
    required BookingDraft draft,
    required String bookingCode,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
  }) async {
    final headers = {...await _headers(), 'Prefer': 'return=minimal'};
    final rows = [draft]
        .map((item) => {
      'booking_code': bookingCode,
      'court_id': item.court.id,
      'court_name': item.court.name,
      'field_name':
      item.court.isClass ? classFieldKey : item.fieldName,
      'booking_date': _dateOnly(item.date),
      'slot_indexes': item.slotIndexes,
      'time_slot': item.timeSlot,
      'duration': item.duration,
      'court_price': item.courtPrice,
      'addons': item.addons
          .map((a) => {
        'name': a.name,
        'price': a.price,
        'quantity': a.quantity,
      })
          .toList(),
      'note': item.note,
      'total_price': item.totalPrice,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      // Pembayaran simulasi langsung sukses -> tidak ada tahap menunggu.
      'status': Booking.statusConfirmed,
    })
        .toList();

    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/bookings'),
      headers: headers,
      body: jsonEncode(rows),
    ));
    if (res.statusCode != 201) throw ApiClient.errorFrom(res);
  }

  // Batalkan reservasi milik sendiri (paling lambat H-1, refund 50%).
  // Aturan dicek di server lewat fungsi cancel_booking.
  // Mengembalikan jumlah refund dalam rupiah.
  Future<int> cancelBooking(String bookingId) async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/rpc/cancel_booking'),
      headers: headers,
      body: jsonEncode({'p_id': bookingId}),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final body = jsonDecode(res.body);
    return body is num ? body.toInt() : 0;
  }
}