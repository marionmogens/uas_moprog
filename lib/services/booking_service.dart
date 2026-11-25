import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/booking.dart';
import '../models/booking_draft.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';

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

  Future<List<Booking>> fetchMyBookings() async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.get(
      Uri.parse('${SupabaseConfig.restUrl}/bookings?select=*&order=created_at.desc'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((row) => Booking.fromJson(row as Map<String, dynamic>))
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
}