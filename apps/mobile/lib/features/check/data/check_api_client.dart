import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/check_result.dart';

String detectType(String raw) {
  final trimmed = raw.trim();
  if (RegExp(r'^\+?[\d\s\-\(\)]{7,}$').hasMatch(trimmed)) return 'phone';
  if (RegExp(r'https?://|www\.').hasMatch(trimmed)) return 'url';
  return 'text';
}

class CheckApiClient {
  CheckApiClient(this._client);

  final http.Client _client;

  Future<CheckResult> check(CheckQuery query) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/check'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'type': query.type,
        'payload': query.payload,
        if (query.source != null) 'meta': {'source': query.source},
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /check failed ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _parse(json);
  }

  CheckResult _parse(Map<String, dynamic> json) {
    final rawMatches = json['matches'] as List<dynamic>;
    return CheckResult(
      verdict: json['verdict'] as String,
      matchedCount: json['matchedCount'] as int,
      matches: rawMatches.map((m) {
        final item = m as Map<String, dynamic>;
        return ReportSummaryItem(
          id: item['id'] as String,
          title: item['title'] as String,
          scamType: item['scamType'] as String,
          verifiedAt: item['verifiedAt'] as String,
        );
      }).toList(),
    );
  }
}
