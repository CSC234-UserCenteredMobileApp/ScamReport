import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class ReportsApi {
  ReportsApi(this._client);

  final http.Client _client;

  Future<Map<String, dynamic>> fetchReportDetail(String id) async {
    final uri = Uri.parse('$apiBaseUrl/reports/$id');
    final response = await _client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );
    if (response.statusCode == 404) {
      throw const ReportNotFoundException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /reports/$id failed with ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class ReportNotFoundException implements Exception {
  const ReportNotFoundException();
}
