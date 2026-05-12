import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/reports_api.dart';
import '../data/reports_repository.dart';
import '../domain/report_detail.dart';

final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(reportsApiProvider));
});

final reportDetailProvider =
    FutureProvider.family<ReportDetail, String>((ref, id) async {
  return ref.read(reportsRepositoryProvider).getReportDetail(id);
});
