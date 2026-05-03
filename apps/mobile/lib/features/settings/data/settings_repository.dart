import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_state.dart';

const _keyTheme = 'settings_theme';
const _keyLanguage = 'settings_language';
const _keyPhoneScam = 'notif_phone_scam';
const _keySmsPhishing = 'notif_sms_phishing';
const _keySmsScanning = 'feature_sms_scanning';

class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  SettingsState load() {
    final themeRaw = _prefs.getString(_keyTheme);
    final themeMode = switch (themeRaw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return SettingsState(
      themeMode: themeMode,
      language: _prefs.getString(_keyLanguage) ?? 'th',
      phoneScamAlerts: _prefs.getBool(_keyPhoneScam) ?? true,
      smsPhishingAlerts: _prefs.getBool(_keySmsPhishing) ?? true,
      smsScanning: _prefs.getBool(_keySmsScanning) ?? false,
    );
  }

  Future<void> save(SettingsState state) async {
    final themeRaw = switch (state.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await Future.wait([
      _prefs.setString(_keyTheme, themeRaw),
      _prefs.setString(_keyLanguage, state.language),
      _prefs.setBool(_keyPhoneScam, state.phoneScamAlerts),
      _prefs.setBool(_keySmsPhishing, state.smsPhishingAlerts),
      _prefs.setBool(_keySmsScanning, state.smsScanning),
    ]);
  }
}
