import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/di/cache.dart';
import '../data/check_api_client.dart';
import '../data/check_repository_impl.dart';
import '../domain/check_repository.dart';
import '../domain/check_result.dart';

final _httpClientProvider = Provider<http.Client>((ref) {
  return ref.watch(httpClientProvider);
});

final checkApiClientProvider = Provider<CheckApiClient>((ref) {
  return CheckApiClient(ref.watch(_httpClientProvider));
});

final checkRepositoryProvider = Provider<CheckRepository>((ref) {
  return CheckRepositoryImpl(
    ref.watch(checkApiClientProvider),
    ref.watch(appDatabaseProvider),
  );
});

final checkResultProvider =
    FutureProvider.family<CheckResult, CheckQuery>((ref, query) async {
  return ref.read(checkRepositoryProvider).runCheck(query);
});
