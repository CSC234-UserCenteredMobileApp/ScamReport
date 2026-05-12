import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class DeletionRequestsApi {
  DeletionRequestsApi(this._client, this._auth);

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

  Future<Map<String, dynamic>> fetchRequests({String? status}) async {
    final uri = Uri.parse('$apiBaseUrl/admin/deletion-requests').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await _client.get(uri, headers: await _authHeaders());
    _check(res, 'GET /admin/deletion-requests');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approve(String id) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/deletion-requests/$id/approve'),
      headers: await _authHeaders(),
    );
    _check(res, 'POST /admin/deletion-requests/$id/approve');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reject(String id, String reason) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/deletion-requests/$id/reject'),
      headers: await _authHeaders(),
      body: jsonEncode({'reason': reason}),
    );
    _check(res, 'POST /admin/deletion-requests/$id/reject');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void _check(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$label failed with ${res.statusCode}: ${res.body}');
    }
  }
}
