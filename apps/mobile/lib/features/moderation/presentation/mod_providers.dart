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

// ---------------------------------------------------------------------------
// Filter + sort state
// ---------------------------------------------------------------------------

// Segmented filter for the queue. `all` shows pending + flagged together.
enum ModQueueSegment { all, pending, flagged }

final modFilterSegmentProvider =
    StateProvider<ModQueueSegment>((ref) => ModQueueSegment.all);

final modSortNewestFirstProvider = StateProvider<bool>((ref) => false);

/// Debounced free-text query that matches case-insensitively against
/// `title`, `scamTypeLabelEn`, and `scamTypeLabelTh`. Empty string disables.
final modSearchQueryProvider = StateProvider<String>((ref) => '');

/// Multi-select scam-type codes (e.g. {'phone_impersonation', 'phishing_sms'}).
/// Empty set disables the filter.
final modScamTypeFilterProvider =
    StateProvider<Set<String>>((ref) => const <String>{});

/// Multi-select AI confidence bands ('high' | 'medium' | 'low' | 'unknown').
/// Empty set disables the filter; null `aiConfidence` on a row is treated as
/// 'unknown' for matching.
final modAiConfidenceFilterProvider =
    StateProvider<Set<String>>((ref) => const <String>{});

/// Show only rows where `priorityFlag == true`.
final modPriorityOnlyProvider = StateProvider<bool>((ref) => false);

/// Show only rows where `evidenceCount > 0`.
final modHasEvidenceOnlyProvider = StateProvider<bool>((ref) => false);

/// True when any of the five user-controlled filters above is active.
/// Drives the "filters applied" affordance in the empty state.
final modAnyFilterActiveProvider = Provider<bool>((ref) {
  return ref.watch(modSearchQueryProvider).isNotEmpty ||
      ref.watch(modScamTypeFilterProvider).isNotEmpty ||
      ref.watch(modAiConfidenceFilterProvider).isNotEmpty ||
      ref.watch(modPriorityOnlyProvider) ||
      ref.watch(modHasEvidenceOnlyProvider);
});

/// Resets the five user-controlled filters (segment + sort are kept — those
/// are top-level navigation, not filters in the same sense).
void resetModFilters(WidgetRef ref) {
  ref.read(modSearchQueryProvider.notifier).state = '';
  ref.read(modScamTypeFilterProvider.notifier).state = const <String>{};
  ref.read(modAiConfidenceFilterProvider.notifier).state = const <String>{};
  ref.read(modPriorityOnlyProvider.notifier).state = false;
  ref.read(modHasEvidenceOnlyProvider.notifier).state = false;
}

// ---------------------------------------------------------------------------
// Composed selector
// ---------------------------------------------------------------------------

final modFilteredQueueProvider =
    Provider<AsyncValue<List<ModQueueItem>>>((ref) {
  final queueAsync = ref.watch(modQueueProvider);
  final segment = ref.watch(modFilterSegmentProvider);
  final newestFirst = ref.watch(modSortNewestFirstProvider);
  final query = ref.watch(modSearchQueryProvider).trim().toLowerCase();
  final scamTypes = ref.watch(modScamTypeFilterProvider);
  final aiConfidences = ref.watch(modAiConfidenceFilterProvider);
  final priorityOnly = ref.watch(modPriorityOnlyProvider);
  final hasEvidenceOnly = ref.watch(modHasEvidenceOnlyProvider);

  return queueAsync.whenData((data) {
    var items = data.items.where((i) {
      // Segment
      switch (segment) {
        case ModQueueSegment.all:
          break;
        case ModQueueSegment.pending:
          if (i.isFlagged) return false;
        case ModQueueSegment.flagged:
          if (!i.isFlagged) return false;
      }
      // Search
      if (query.isNotEmpty) {
        final hit = i.title.toLowerCase().contains(query) ||
            i.scamTypeLabelEn.toLowerCase().contains(query) ||
            i.scamTypeLabelTh.contains(query);
        if (!hit) return false;
      }
      // Scam type
      if (scamTypes.isNotEmpty && !scamTypes.contains(i.scamTypeCode)) {
        return false;
      }
      // AI confidence
      if (aiConfidences.isNotEmpty) {
        final tier = i.aiConfidence ?? 'unknown';
        if (!aiConfidences.contains(tier)) return false;
      }
      // Priority flag
      if (priorityOnly && !i.priorityFlag) return false;
      // Has evidence
      if (hasEvidenceOnly && i.evidenceCount <= 0) return false;
      return true;
    }).toList();
    items.sort((a, b) => newestFirst
        ? b.submittedAt.compareTo(a.submittedAt)
        : a.submittedAt.compareTo(b.submittedAt));
    return items;
  });
});
