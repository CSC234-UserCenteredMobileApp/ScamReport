import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../data/home_api.dart';
import '../data/home_repository.dart';
import '../domain/home_stats.dart';
import '../domain/recent_alert.dart';
import '../domain/recent_report.dart';

final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.watch(httpClientProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(homeApiProvider));
});

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  return ref.read(homeRepositoryProvider).getStats();
});

final recentAlertsProvider = FutureProvider<List<RecentAlert>>((ref) async {
  return ref.read(homeRepositoryProvider).getRecentAlerts();
});

final recentReportsProvider = FutureProvider<List<RecentReport>>((ref) async {
  return ref.read(homeRepositoryProvider).getRecentReports();
});
