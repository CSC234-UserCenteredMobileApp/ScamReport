import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(authApiProvider),
  );
});

// The synced backend user. Resolves null when signed out.
// Re-syncs automatically when Firebase auth state changes.
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return null;
  return ref.read(authRepositoryProvider).sync();
});
