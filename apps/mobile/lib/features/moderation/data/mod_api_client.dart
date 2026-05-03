import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class ModApiClient {
  ModApiClient(this._client, this._auth);

  final http.Client _client;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final token = await user.getIdToken();
    if (token == null) throw StateError('Failed to get ID token');
    return {
      'Authorization': 'Bearer $token',
      'content-type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> fetchQueue() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/admin/reports/queue'),
      headers: await _authHeaders(),
    );
    _check(res, 'GET /admin/reports/queue');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchDetail(String reportId) async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/admin/reports/$reportId'),
      headers: await _authHeaders(),
    );
    _check(res, 'GET /admin/reports/$reportId');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> postAction(String reportId, String action, String remark) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/reports/$reportId/$action'),
      headers: await _authHeaders(),
      body: jsonEncode({'remark': remark}),
    );
    _check(res, 'POST /admin/reports/$reportId/$action');
  }

  void _check(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$label failed with ${res.statusCode}: ${res.body}');
    }
  }
}
