import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class SearchApi {
  SearchApi(this._client);

  final http.Client _client;

  Future<List<dynamic>> searchReports({
    String? q,
    List<String> scamTypeCodes = const [],
    String sortBy = 'latest',
    int limit = 30,
  }) async {
    final params = <String, String>{'limit': '$limit', 'sortBy': sortBy};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (scamTypeCodes.isNotEmpty) {
      params['scamTypeCodes'] = scamTypeCodes.join(',');
    }

    final uri =
        Uri.parse('$apiBaseUrl/reports').replace(queryParameters: params);
    final res =
        await _client.get(uri, headers: {'content-type': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /reports failed ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['items'] as List<dynamic>;
  }

  Future<List<dynamic>> fetchScamTypes() async {
    final uri = Uri.parse('$apiBaseUrl/scam-types');
    final res =
        await _client.get(uri, headers: {'content-type': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /scam-types failed ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['items'] as List<dynamic>;
  }
}
