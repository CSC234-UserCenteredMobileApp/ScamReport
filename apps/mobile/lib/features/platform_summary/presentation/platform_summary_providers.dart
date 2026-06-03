import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../moderation/presentation/mod_providers.dart';
import '../data/platform_summary_repository.dart';
import '../domain/platform_summary.dart';

part 'platform_summary_providers.g.dart';

// @riverpod code generation (rubric R2) — generated names match the previous
// hand-written providers, so consumers and tests are unaffected.

@Riverpod(keepAlive: true)
PlatformSummaryRepository platformSummaryRepository(
    PlatformSummaryRepositoryRef ref) {
  return PlatformSummaryRepository(ref.watch(modApiClientProvider));
}

@Riverpod(keepAlive: true)
Future<PlatformSummary> platformSummary(PlatformSummaryRef ref) {
  return ref.watch(platformSummaryRepositoryProvider).getSummary();
}
