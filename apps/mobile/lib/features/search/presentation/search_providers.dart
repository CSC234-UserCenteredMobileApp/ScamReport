import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../home/domain/recent_report.dart';
import '../data/search_api.dart';
import '../data/search_repository.dart';
import '../domain/scam_type_item.dart';

final searchApiProvider = Provider<SearchApi>((ref) {
  return SearchApi(ref.watch(httpClientProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(searchApiProvider));
});

/// Current query text; empty = no text filter.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected scam type codes for filter; empty = all types.
final searchScamTypeFilterProvider = StateProvider<List<String>>((ref) => const []);

/// Sort mode: 'latest' or 'reportCount'.
final searchSortByProvider = StateProvider<String>((ref) => 'latest');

/// Scam types list for filter checkboxes.
final scamTypesProvider = FutureProvider<List<ScamTypeItem>>((ref) async {
  return ref.read(searchRepositoryProvider).getScamTypes();
});

/// Search results. Re-fetches when query/filter/sort changes.
/// Fires when: q is non-empty, scam type filter applied, or sort != default.
final searchResultsProvider = FutureProvider<List<RecentReport>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  final codes = ref.watch(searchScamTypeFilterProvider);
  final sortBy = ref.watch(searchSortByProvider);

  if (q.trim().isEmpty && codes.isEmpty && sortBy == 'latest') return [];

  return ref.read(searchRepositoryProvider).searchReports(
    q: q.trim().isEmpty ? null : q.trim(),
    scamTypeCodes: codes,
    sortBy: sortBy,
  );
});
