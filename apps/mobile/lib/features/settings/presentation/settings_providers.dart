import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/cache.dart';
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
