import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsRepository.load', () {
    test('returns defaults when prefs are empty', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      final state = repo.load();

      expect(state.language, 'th');
      expect(state.smsScanning, false);
      expect(state.themeMode, ThemeMode.system);
      expect(state.phoneScamAlerts, true);
      expect(state.smsPhishingAlerts, true);
    });

    test('maps stored theme value "light" to ThemeMode.light', () async {
      SharedPreferences.setMockInitialValues({'settings_theme': 'light'});
      final prefs = await SharedPreferences.getInstance();
      expect(SettingsRepository(prefs).load().themeMode, ThemeMode.light);
    });

    test('maps stored theme value "dark" to ThemeMode.dark', () async {
      SharedPreferences.setMockInitialValues({'settings_theme': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      expect(SettingsRepository(prefs).load().themeMode, ThemeMode.dark);
    });

    test('falls back to ThemeMode.system for unknown theme value', () async {
      SharedPreferences.setMockInitialValues({'settings_theme': 'unknown'});
      final prefs = await SharedPreferences.getInstance();
      expect(SettingsRepository(prefs).load().themeMode, ThemeMode.system);
    });

    test('restores stored language', () async {
      SharedPreferences.setMockInitialValues({'settings_language': 'en'});
      final prefs = await SharedPreferences.getInstance();
      expect(SettingsRepository(prefs).load().language, 'en');
    });
  });

  group('SettingsRepository.save + load round-trip', () {
    test('persists all five fields', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      const saved = SettingsState(
        themeMode: ThemeMode.dark,
        language: 'en',
        phoneScamAlerts: false,
        smsPhishingAlerts: false,
        smsScanning: true,
      );

      await repo.save(saved);
      final loaded = repo.load();

      expect(loaded.themeMode, ThemeMode.dark);
      expect(loaded.language, 'en');
      expect(loaded.phoneScamAlerts, false);
      expect(loaded.smsPhishingAlerts, false);
      expect(loaded.smsScanning, true);
    });
  });

  group('SettingsRepository SMS consent', () {
    test('smsScanConsentGiven is false when key absent', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(SettingsRepository(prefs).smsScanConsentGiven, false);
    });

    test('setSmsScanConsentGiven makes smsScanConsentGiven true', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await repo.setSmsScanConsentGiven();
      expect(repo.smsScanConsentGiven, true);
    });
  });
}
