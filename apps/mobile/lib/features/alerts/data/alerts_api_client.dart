import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class AlertsApiClient {
  AlertsApiClient(this._client);

  final http.Client _client;

  Future<List<dynamic>> fetchAlerts({int limit = 20}) async {
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
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['items'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchAlert(String id) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/announcements/$id'),
      headers: {'content-type': 'application/json'},
    );
    if (response.statusCode == 404) {
      throw Exception('Announcement not found: $id');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /announcements/$id failed with ${response.statusCode}: ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['item'] as Map<String, dynamic>;
  }
}
