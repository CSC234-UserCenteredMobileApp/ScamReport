import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/mod_api_client.dart';
import '../data/mod_repository_impl.dart';
import '../domain/mod_report.dart';
import '../domain/mod_repository.dart';

final modApiClientProvider = Provider<ModApiClient>((ref) {
  return ModApiClient(ref.watch(httpClientProvider), ref.watch(firebaseAuthProvider));
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

final modFilterFlaggedProvider = StateProvider<bool>((ref) => false);

final modSortNewestFirstProvider = StateProvider<bool>((ref) => false);

final modFilteredQueueProvider =
    Provider<AsyncValue<List<ModQueueItem>>>((ref) {
  final queueAsync = ref.watch(modQueueProvider);
  final flaggedOnly = ref.watch(modFilterFlaggedProvider);
  final newestFirst = ref.watch(modSortNewestFirstProvider);
  return queueAsync.whenData((data) {
    var items = flaggedOnly
        ? data.items.where((i) => i.isFlagged).toList()
        : List<ModQueueItem>.from(data.items);
    items.sort((a, b) => newestFirst
        ? b.submittedAt.compareTo(a.submittedAt)
        : a.submittedAt.compareTo(b.submittedAt));
    return items;
  });
});
