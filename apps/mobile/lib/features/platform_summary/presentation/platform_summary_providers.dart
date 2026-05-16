import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moderation/presentation/mod_providers.dart';
import '../data/platform_summary_repository.dart';
import '../domain/platform_summary.dart';

final platformSummaryRepositoryProvider =
    Provider<PlatformSummaryRepository>((ref) {
  return PlatformSummaryRepository(ref.watch(modApiClientProvider));
});

final platformSummaryProvider = FutureProvider<PlatformSummary>((ref) async {
  return ref.watch(platformSummaryRepositoryProvider).getSummary();
});
