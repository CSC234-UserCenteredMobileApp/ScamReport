import 'package:flutter/material.dart';

import '../domain/settings_state.dart';

/// Presentation-edge mapping: the domain stores [AppThemeMode] (pure Dart);
/// Flutter widgets need [ThemeMode].
extension AppThemeModeX on AppThemeMode {
  ThemeMode get material => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };
}
