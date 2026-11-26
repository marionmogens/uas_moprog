import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/padel_court.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class VenueService {
  VenueService._();
  static final VenueService instance = VenueService._();

  final AuthService _auth = AuthService.instance;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidToken();
    return _auth.authHeaders(token);
  }

  List<PadelCourt> _parse(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return list
        .map((row) => PadelCourt.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ---------------- PELANGGAN ----------------
  Future<List<PadelCourt>> fetchApproved() async {
    final headers = await _auth.readHeaders();
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/venues?status=eq.disetujui&select=*&order=created_at.desc,name.asc'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    return _parse(res.body);
  }

  // ---------------- PEMILIK ----------------
  Future<List<PadelCourt>> fetchMine() async {
    final headers = await _headers();
    final uid = _auth.currentUser!.id;
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/venues?owner_id=eq.$uid&select=*&order=created_at.desc'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    return _parse(res.body);
  }

  Future<void> create(Map<String, dynamic> data) async {
    final headers = {...await _headers(), 'Prefer': 'return=minimal'};
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/venues'),
      headers: headers,
      body: jsonEncode(data),
    ));
    if (res.statusCode != 201) throw ApiClient.errorFrom(res);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final headers = {...await _headers(), 'Prefer': 'return=representation'};
    final res = await ApiClient.send(() => http.patch(
      Uri.parse('${SupabaseConfig.restUrl}/venues?id=eq.$id'),
      headers: headers,
      body: jsonEncode(data),
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    if ((jsonDecode(res.body) as List).isEmpty) {
      throw const ApiException('Perubahan gagal disimpan.');
    }
  }

  Future<void> setAccepting(String id, bool value) =>
      update(id, {'accepting_bookings': value});

  Future<void> resubmit(String id) async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/rpc/resubmit_venue'),
      headers: headers,
      body: jsonEncode({'p_id': id}),
    ));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw ApiClient.errorFrom(res);
    }
  }

  // ---------------- ADMIN ----------------
  Future<List<PadelCourt>> fetchAllForAdmin() async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/venues?select=*,owner:profiles!owner_id(full_name,phone,email)&order=created_at.desc'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    return _parse(res.body);
  }

  Future<void> adminReview(String id, String decision, {String reason = ''}) async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/rpc/review_venue'),
      headers: headers,
      body: jsonEncode({'p_id': id, 'p_decision': decision, 'p_reason': reason}),
    ));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw ApiClient.errorFrom(res);
    }
  }
}