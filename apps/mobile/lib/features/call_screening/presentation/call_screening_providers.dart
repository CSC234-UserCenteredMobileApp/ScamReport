import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/di/cache.dart';
import '../data/call_screening_api_client.dart';
import '../data/call_screening_repository_impl.dart';
import '../domain/blocked_call.dart';
import '../domain/call_screening_repository.dart';

const _channel = MethodChannel('com.example.mobile/call_screening');

final callScreeningApiClientProvider = Provider<CallScreeningApiClient>((ref) {
  return CallScreeningApiClient(
    client: ref.watch(httpClientProvider),
    baseUrl: apiBaseUrl,
  );
});

final callScreeningRepositoryProvider =
    FutureProvider<CallScreeningRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return CallScreeningRepositoryImpl(
    apiClient: ref.watch(callScreeningApiClientProvider),
    prefs: prefs,
  );
});

final callScreeningSdkVersionProvider = FutureProvider<int>((ref) async {
  try {
    final v = await _channel.invokeMethod<int>('getSdkVersion');
    return v ?? 0;
  } on MissingPluginException {
    return 0;
  }
});

final callScreeningIsDefaultProvider = FutureProvider<bool>((ref) async {
  try {
    final v = await _channel.invokeMethod<bool>('isServiceDefault');
    return v ?? false;
  } on MissingPluginException {
    return false;
  }
});

final callScreeningEnabledProvider = StateProvider<bool>((ref) => false);

final blockedCallsProvider = FutureProvider<List<BlockedCall>>((ref) async {
  final repo = await ref.watch(callScreeningRepositoryProvider.future);
  return repo.getBlockedCalls();
});
