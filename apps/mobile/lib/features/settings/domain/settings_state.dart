import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.language,
    required this.phoneScamAlerts,
    required this.smsPhishingAlerts,
  });

  final ThemeMode themeMode;
  final String language; // 'en' | 'th'
  final bool phoneScamAlerts;
  final bool smsPhishingAlerts;

  static const SettingsState defaults = SettingsState(
    themeMode: ThemeMode.system,
    language: 'th',
    phoneScamAlerts: true,
    smsPhishingAlerts: true,
  );

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? phoneScamAlerts,
    bool? smsPhishingAlerts,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      phoneScamAlerts: phoneScamAlerts ?? this.phoneScamAlerts,
      smsPhishingAlerts: smsPhishingAlerts ?? this.smsPhishingAlerts,
    );
  }
}
