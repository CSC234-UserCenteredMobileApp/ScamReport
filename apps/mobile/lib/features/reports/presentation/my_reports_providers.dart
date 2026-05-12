import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/my_report.dart';
import 'report_detail_providers.dart';

export 'report_detail_providers.dart' show reportsApiProvider, reportsRepositoryProvider;

final myReportsProvider = FutureProvider<List<MyReport>>((ref) {
  return ref.watch(reportsRepositoryProvider).getMyReports();
});

// Active filter: null = All
final myReportsFilterProvider = StateProvider<MyReportStatus?>((ref) => null);

final filteredMyReportsProvider = Provider<AsyncValue<List<MyReport>>>((ref) {
  final all = ref.watch(myReportsProvider);
  final filter = ref.watch(myReportsFilterProvider);
  if (filter == null) return all;
  return all.whenData(
    (items) => items.where((r) => r.status == filter).toList(),
  );
});
