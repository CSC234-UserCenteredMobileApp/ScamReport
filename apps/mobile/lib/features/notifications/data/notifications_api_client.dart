import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class NotificationsApiFailure implements Exception {
  NotificationsApiFailure({
    required this.statusCode,
    required this.serverMessage,
    required this.action,
  });

  final int statusCode;
  final String serverMessage;
  final String action;

  @override
  String toString() =>
      'NotificationsApiFailure(status: $statusCode, action: $action, message: $serverMessage)';
}

class NotificationsApiClient {
  NotificationsApiClient(this._client, this._auth);

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

  Future<Map<String, dynamic>> fetchInbox() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/me/notifications'),
      headers: await _authHeaders(),
    );
    _check(res, 'inbox');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markRead(List<String> ids) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/me/notifications/read'),
      headers: await _authHeaders(),
      body: jsonEncode({'ids': ids}),
    );
    _check(res, 'mark-read');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> registerToken({
    required String fcmToken,
    required String platform,
    String? appVersion,
  }) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/me/fcm-tokens'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'fcmToken': fcmToken,
        'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
      }),
    );
    _check(res, 'register-token');
  }

  Future<void> unregisterToken(String fcmToken) async {
    final res = await _client.delete(
      Uri.parse('$apiBaseUrl/me/fcm-tokens/${Uri.encodeComponent(fcmToken)}'),
      headers: await _authHeaders(),
    );
    // 404 is acceptable on unregister — token may already be gone.
    if (res.statusCode == 404) return;
    _check(res, 'unregister-token');
  }

  void _check(http.Response res, String action) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw NotificationsApiFailure(
      statusCode: res.statusCode,
      serverMessage: _extractMessage(res.body),
      action: action,
    );
  }

  String _extractMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return trimmed.length > 280 ? '${trimmed.substring(0, 280)}…' : trimmed;
  }
}
