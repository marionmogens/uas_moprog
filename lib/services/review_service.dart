import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/review.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'api_exception.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final AuthService _auth = AuthService.instance;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidToken();
    return _auth.authHeaders(token);
  }

  List<Review> _parse(String body) => (jsonDecode(body) as List<dynamic>)
      .map((r) => Review.fromJson(r as Map<String, dynamic>))
      .toList();

  Future<List<Review>> fetchForVenue(String venueId, {int limit = 20}) async {
    final headers = await _auth.readHeaders();
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/reviews?venue_id=eq.$venueId&select=*&order=created_at.desc&limit=$limit'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    return _parse(res.body);
  }

  Future<List<Review>> fetchAll() async {
    final headers = await _headers();
    final res = await ApiClient.send(() => http.get(
      Uri.parse(
          '${SupabaseConfig.restUrl}/reviews?select=*,venue:venues(name)&order=created_at.desc&limit=200'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    return _parse(res.body);
  }

  Future<void> submit({
    required String venueId,
    required int rating,
    required String comment,
  }) async {
    final headers = {
      ...await _headers(),
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    };
    final res = await ApiClient.send(() => http.post(
      Uri.parse('${SupabaseConfig.restUrl}/reviews?on_conflict=venue_id,user_id'),
      headers: headers,
      body: jsonEncode({
        'venue_id': venueId,
        'rating': rating,
        'comment': comment.trim(),
      }),
    ));
    if (res.statusCode != 201 && res.statusCode != 204 && res.statusCode != 200) {
      throw ApiClient.errorFrom(res);
    }
  }

  // Hapus ulasan. Yang boleh hanya PEMILIK tempat tersebut (dijaga RLS di
  // database). Jika bukan ulasan di tempatnya, database menghapus 0 baris,
  // jadi hasilnya dicek supaya tidak terlihat "berhasil" padahal tidak.
  Future<void> delete(String reviewId) async {
    final headers = {...await _headers(), 'Prefer': 'return=representation'};
    final res = await ApiClient.send(() => http.delete(
      Uri.parse('${SupabaseConfig.restUrl}/reviews?id=eq.$reviewId'),
      headers: headers,
    ));
    if (res.statusCode != 200) throw ApiClient.errorFrom(res);
    final deleted = jsonDecode(res.body) as List<dynamic>;
    if (deleted.isEmpty) {
      throw const ApiException(
          'Ulasan ini tidak bisa dihapus. Hanya pemilik tempatnya yang bisa menghapus.');
    }
  }
}