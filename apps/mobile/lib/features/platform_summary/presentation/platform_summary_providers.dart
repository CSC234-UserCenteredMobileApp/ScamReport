import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../moderation/presentation/mod_providers.dart';
import '../data/platform_summary_repository.dart';
import '../domain/platform_summary.dart';

part 'platform_summary_providers.g.dart';

// @riverpod code generation (rubric R2) — generated names match the previous
// hand-written providers, so consumers and tests are unaffected.

@Riverpod(keepAlive: true)
PlatformSummaryRepository platformSummaryRepository(Ref ref) {
  return PlatformSummaryRepository(ref.watch(modApiClientProvider));
}

@Riverpod(keepAlive: true)
Future<PlatformSummary> platformSummary(Ref ref) {
  return ref.watch(platformSummaryRepositoryProvider).getSummary();
}
