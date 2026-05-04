import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/cache.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_state.dart';
import 'package:mobile/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _container() {
  return ProviderContainer();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsNotifier', () {
    test('loads SettingsState.defaults from empty prefs', () async {
      final container = _container();
      addTearDown(container.dispose);

      final state = await container.read(settingsProvider.future);

      expect(state.language, 'th');
      expect(state.smsScanning, false);
      expect(state.themeMode, ThemeMode.system);
      expect(state.phoneScamAlerts, true);
    });

    test('save updates provider state immediately', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);

      const updated = SettingsState(
        themeMode: ThemeMode.dark,
        language: 'en',
        phoneScamAlerts: false,
        smsPhishingAlerts: false,
        smsScanning: true,
      );

      await container.read(settingsProvider.notifier).save(updated);

      final newState = container.read(settingsProvider).requireValue;
      expect(newState.themeMode, ThemeMode.dark);
      expect(newState.language, 'en');
      expect(newState.smsScanning, true);
    });
  });

  group('settingsRepositoryProvider', () {
    test('returns a SettingsRepository instance', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) async => prefs,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(sharedPreferencesProvider.future);
      final repo = container.read(settingsRepositoryProvider);
      expect(repo, isA<SettingsRepository>());
    });
  });
}
