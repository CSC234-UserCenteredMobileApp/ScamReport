import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import 'mod_action_failure.dart';

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
    _check(res, 'queue');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchDetail(String reportId) async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/admin/reports/$reportId'),
      headers: await _authHeaders(),
    );
    _check(res, 'detail');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> postAction(String reportId, String action, String remark) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/reports/$reportId/$action'),
      headers: await _authHeaders(),
      body: jsonEncode({'remark': remark}),
    );
    _check(res, action);
  }

  void _check(http.Response res, String action) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ModActionFailure(
      statusCode: res.statusCode,
      serverMessage: _extractMessage(res.body),
      action: action,
    );
  }

  // Pull a human-readable message out of the response body. The API returns
  // `{ "error": "..." }` on 4xx + 5xx; non-JSON bodies fall through to a
  // trimmed raw string so nothing is hidden from the admin.
  String _extractMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Fall through to raw body — body wasn't JSON.
    }
    return trimmed.length > 280 ? '${trimmed.substring(0, 280)}…' : trimmed;
  }
}
