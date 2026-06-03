import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api_client.dart';
import '../data/home_api.dart';
import '../data/home_repository.dart';
import '../domain/home_stats.dart';
import '../domain/recent_alert.dart';
import '../domain/recent_report.dart';

part 'home_providers.g.dart';

// Declared with the @riverpod code generator (rubric R2). keepAlive matches
// the previous hand-written Provider/FutureProvider semantics, and the
// generated names (homeApiProvider, homeStatsProvider, ...) are identical so
// call sites and test overrides are unaffected.

@Riverpod(keepAlive: true)
HomeApi homeApi(HomeApiRef ref) {
  return HomeApi(ref.watch(httpClientProvider));
}

@Riverpod(keepAlive: true)
HomeRepository homeRepository(HomeRepositoryRef ref) {
  return HomeRepository(ref.watch(homeApiProvider));
}

@Riverpod(keepAlive: true)
Future<HomeStats> homeStats(HomeStatsRef ref) {
  return ref.read(homeRepositoryProvider).getStats();
}

@Riverpod(keepAlive: true)
Future<List<RecentAlert>> recentAlerts(RecentAlertsRef ref) {
  return ref.read(homeRepositoryProvider).getRecentAlerts();
}

@Riverpod(keepAlive: true)
Future<List<RecentReport>> recentReports(RecentReportsRef ref) {
  return ref.read(homeRepositoryProvider).getRecentReports();
}
