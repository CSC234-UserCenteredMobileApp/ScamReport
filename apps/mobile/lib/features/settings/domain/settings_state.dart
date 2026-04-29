import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.language,
    required this.phoneScamAlerts,
    required this.smsPhishingAlerts,
    required this.regionalAlerts,
    this.province,
  });

  final ThemeMode themeMode;
  final String language; // 'en' | 'th'
  final bool phoneScamAlerts;
  final bool smsPhishingAlerts;
  final bool regionalAlerts;
  final String? province;

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
    String? province,
    bool clearProvince = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      phoneScamAlerts: phoneScamAlerts ?? this.phoneScamAlerts,
      smsPhishingAlerts: smsPhishingAlerts ?? this.smsPhishingAlerts,
      regionalAlerts: regionalAlerts ?? this.regionalAlerts,
      province: clearProvince ? null : (province ?? this.province),
    );
  }
}
