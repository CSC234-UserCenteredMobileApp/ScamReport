import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_state.dart';

const _keyTheme = 'settings_theme';
const _keyLanguage = 'settings_language';
const _keyPhoneScam = 'notif_phone_scam';
const _keySmsPhishing = 'notif_sms_phishing';
const _keySmsScanning = 'feature_sms_scanning';
const _keyConsentSmsScanning = 'sms_scan_consent_given';

class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  SettingsState load() {
    final themeRaw = _prefs.getString(_keyTheme);
    final themeMode = switch (themeRaw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };

    return SettingsState(
      themeMode: themeMode,
      language: _prefs.getString(_keyLanguage) ?? 'th',
      phoneScamAlerts: _prefs.getBool(_keyPhoneScam) ?? true,
      smsPhishingAlerts: _prefs.getBool(_keySmsPhishing) ?? true,
      smsScanning: _prefs.getBool(_keySmsScanning) ?? false,
    );
  }

  bool get smsScanConsentGiven =>
      _prefs.getBool(_keyConsentSmsScanning) ?? false;

  Future<void> setSmsScanConsentGiven() =>
      _prefs.setBool(_keyConsentSmsScanning, true);

  Future<void> save(SettingsState state) async {
    final themeRaw = switch (state.themeMode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      AppThemeMode.system => 'system',
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
