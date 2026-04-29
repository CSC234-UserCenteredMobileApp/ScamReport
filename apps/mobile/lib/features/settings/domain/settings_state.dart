import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.language,
    required this.phoneScamAlerts,
    required this.smsPhishingAlerts,
    required this.regionalAlerts,
  });

  final ThemeMode themeMode;
  final String language; // 'en' | 'th'
  final bool phoneScamAlerts;
  final bool smsPhishingAlerts;
  final bool regionalAlerts;

  static const SettingsState defaults = SettingsState(
    themeMode: ThemeMode.system,
    language: 'th',
    phoneScamAlerts: true,
    smsPhishingAlerts: true,
    regionalAlerts: false,
  );

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? phoneScamAlerts,
    bool? smsPhishingAlerts,
    bool? regionalAlerts,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      phoneScamAlerts: phoneScamAlerts ?? this.phoneScamAlerts,
      smsPhishingAlerts: smsPhishingAlerts ?? this.smsPhishingAlerts,
      regionalAlerts: regionalAlerts ?? this.regionalAlerts,
    );
  }
}
