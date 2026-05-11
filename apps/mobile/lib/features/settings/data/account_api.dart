import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class AccountApi {
  AccountApi(this._client, this._auth);

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

  Future<Map<String, dynamic>> requestDeletion() async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/user/delete-account'),
      headers: await _authHeaders(),
    );
    _check(res, 'POST /user/delete-account');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> cancelDeletion() async {
    final res = await _client.delete(
      Uri.parse('$apiBaseUrl/user/delete-account'),
      headers: await _authHeaders(),
    );
    _check(res, 'DELETE /user/delete-account');
  }

  void _check(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$label failed with ${res.statusCode}: ${res.body}');
    }
  }
}
