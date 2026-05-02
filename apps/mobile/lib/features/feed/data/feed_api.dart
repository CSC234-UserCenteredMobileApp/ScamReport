import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class FeedApi {
  FeedApi(this._client);

  final http.Client _client;

  Future<List<dynamic>> fetchReports({int limit = 50}) async {
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
