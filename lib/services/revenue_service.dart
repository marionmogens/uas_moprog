import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/revenue.dart';
import 'api_client.dart';
import 'auth_service.dart';

// Mengambil pendapatan per tempat lewat fungsi database `venue_revenue()`.
// Fungsi itu sendiri yang menentukan isinya: admin melihat semua tempat,
// pemilik hanya tempat miliknya (lihat supabase/10_step_ulasan_pendapatan.sql).
class RevenueService {
  RevenueService._();
  static final RevenueService instance = RevenueService._();

  final AuthService _auth = AuthService.instance;

  Future<RevenueSummary> fetch() async {
    final token = await _auth.getValidToken();
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/rpc/venue_revenue'),
      headers: _auth.authHeaders(token),
      body: jsonEncode({}),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);

    final list = jsonDecode(res.body) as List<dynamic>;
    return RevenueSummary(
      list.map((r) => VenueRevenue.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}