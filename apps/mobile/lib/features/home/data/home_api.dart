import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class HomeApi {
  HomeApi(this._client);

  final http.Client _client;

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/stats'),
      headers: {'content-type': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /stats failed with ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchRecentAlerts({int limit = 2}) async {
    final uri = Uri.parse('$apiBaseUrl/announcements').replace(
      queryParameters: {'limit': '$limit'},
    );
    final response = await _client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /announcements failed with ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['items'] as List<dynamic>;
  }

  Future<List<dynamic>> fetchRecentReports({int limit = 2}) async {
    final uri = Uri.parse('$apiBaseUrl/reports').replace(
      queryParameters: {'limit': '$limit'},
    );
    final response = await _client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /reports failed with ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['items'] as List<dynamic>;
  }
}
