import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/deletion_requests_api.dart';
import '../domain/deletion_request.dart';

final deletionRequestsApiProvider = Provider<DeletionRequestsApi>((ref) {
  return DeletionRequestsApi(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final deletionRequestsProvider =
    FutureProvider.family<List<DeletionRequest>, String?>((ref, status) async {
  final api = ref.watch(deletionRequestsApiProvider);
  final data = await api.fetchRequests(status: status);
  final items = data['items'] as List<dynamic>;
  return items
      .map((e) => DeletionRequest.fromJson(e as Map<String, dynamic>))
      .toList();
});

final deletionStatusFilterProvider =
    StateProvider<DeletionRequestStatus?>((ref) => DeletionRequestStatus.pending);
