import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/mod_api_client.dart';
import '../data/mod_repository_impl.dart';
import '../domain/mod_report.dart';
import '../domain/mod_repository.dart';

final modApiClientProvider = Provider<ModApiClient>((ref) {
  return ModApiClient(
      ref.watch(httpClientProvider), ref.watch(firebaseAuthProvider));
});

final modRepositoryProvider = Provider<ModRepository>((ref) {
  return ModRepositoryImpl(ref.watch(modApiClientProvider));
});

final modQueueProvider = FutureProvider<ModQueueData>((ref) async {
  return ref.watch(modRepositoryProvider).getQueue();
});

final modDetailProvider =
    FutureProvider.family<ModReportDetail, String>((ref, id) async {
  return ref.watch(modRepositoryProvider).getDetail(id);
});

// Segmented filter for the queue. `all` shows pending + flagged together.
enum ModQueueSegment { all, pending, flagged }

final modFilterSegmentProvider =
    StateProvider<ModQueueSegment>((ref) => ModQueueSegment.all);

final modSortNewestFirstProvider = StateProvider<bool>((ref) => false);

final modFilteredQueueProvider =
    Provider<AsyncValue<List<ModQueueItem>>>((ref) {
  final queueAsync = ref.watch(modQueueProvider);
  final segment = ref.watch(modFilterSegmentProvider);
  final newestFirst = ref.watch(modSortNewestFirstProvider);
  return queueAsync.whenData((data) {
    var items = data.items.where((i) {
      switch (segment) {
        case ModQueueSegment.all:
          return true;
        case ModQueueSegment.pending:
          return !i.isFlagged;
        case ModQueueSegment.flagged:
          return i.isFlagged;
      }
    }).toList();
    items.sort((a, b) => newestFirst
        ? b.submittedAt.compareTo(a.submittedAt)
        : a.submittedAt.compareTo(b.submittedAt));
    return items;
  });
});
