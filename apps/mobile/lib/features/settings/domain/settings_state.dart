/// Theme preference as a pure domain value. Mapped to Flutter's `ThemeMode`
/// at the presentation edge (see presentation/theme_mode_x.dart) so the
/// domain layer stays free of Flutter imports.
enum AppThemeMode { light, dark, system }

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.language,
    required this.phoneScamAlerts,
    required this.smsPhishingAlerts,
    required this.smsScanning,
  });

  final AppThemeMode themeMode;
  final String language; // 'en' | 'th'
  final bool phoneScamAlerts;
  final bool smsPhishingAlerts;
  final bool smsScanning;

  static const SettingsState defaults = SettingsState(
    themeMode: AppThemeMode.system,
    language: 'th',
    phoneScamAlerts: true,
    smsPhishingAlerts: true,
    smsScanning: false,
  );

  SettingsState copyWith({
    AppThemeMode? themeMode,
    String? language,
    bool? phoneScamAlerts,
    bool? smsPhishingAlerts,
    bool? smsScanning,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      phoneScamAlerts: phoneScamAlerts ?? this.phoneScamAlerts,
      smsPhishingAlerts: smsPhishingAlerts ?? this.smsPhishingAlerts,
      smsScanning: smsScanning ?? this.smsScanning,
    );
  }
}
