import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/edit_report_detail.dart';
import 'my_reports_providers.dart';

export 'my_reports_providers.dart'
    show reportsRepositoryProvider, myReportsProvider;

class ScamTypeOption {
  const ScamTypeOption({
    required this.code,
    required this.labelEn,
    required this.labelTh,
  });

  final String code;
  final String labelEn;
  final String labelTh;
}

final editReportDetailProvider =
    FutureProvider.family<EditReportDetail, String>((ref, id) {
  return ref.watch(reportsRepositoryProvider).getMyReportDetail(id);
});

final editScamTypesProvider = FutureProvider<List<ScamTypeOption>>((ref) async {
  final client = ref.watch(httpClientProvider);
  final response = await client.get(
    Uri.parse('$apiBaseUrl/scam-types'),
    headers: {'content-type': 'application/json'},
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to load scam types (HTTP ${response.statusCode})');
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final items = body['items'] as List<dynamic>;
  return items.map((e) {
    final item = e as Map<String, dynamic>;
    return ScamTypeOption(
      code: item['code'] as String,
      labelEn: item['labelEn'] as String,
      labelTh: item['labelTh'] as String,
    );
  }).toList();
});
