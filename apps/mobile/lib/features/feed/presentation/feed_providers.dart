import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../home/domain/recent_report.dart';
import '../data/feed_api.dart';
import '../data/feed_repository.dart';

final feedApiProvider = Provider<FeedApi>((ref) {
  return FeedApi(ref.watch(httpClientProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(feedApiProvider));
});

final feedReportsProvider = FutureProvider<List<RecentReport>>((ref) async {
  return ref.read(feedRepositoryProvider).getReports();
});

/// Selected scam type code; null = All.
final feedFilterProvider = StateProvider<String?>((ref) => null);
