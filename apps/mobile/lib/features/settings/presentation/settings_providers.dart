import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../../../core/di/cache.dart';
import '../data/account_api.dart';
import '../data/settings_repository.dart';
import '../domain/settings_state.dart';

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return SettingsRepository(prefs).load();
  }

  Future<void> save(SettingsState next) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await SettingsRepository(prefs).save(next);
    state = AsyncValue.data(next);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefsAsync.requireValue);
});

final accountApiProvider = Provider<AccountApi>((ref) {
  return AccountApi(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class DeleteAccountNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> requestDeletion() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountApiProvider).requestDeletion();
      // Sign out AFTER API success — deletion is committed in the API
      await ref.read(firebaseAuthProvider).signOut();
    });
  }
}

final deleteAccountProvider =
    AsyncNotifierProvider<DeleteAccountNotifier, void>(
  DeleteAccountNotifier.new,
);
