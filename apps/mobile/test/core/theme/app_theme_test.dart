import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    testWidgets('lightTheme has correct brightness and extension', (tester) async {
      final theme = lightTheme();
      expect(theme.brightness, Brightness.light);
      final palette = theme.extension<VerdictPalette>();
      expect(palette, isNotNull);
      expect(palette!.scam.fg, const Color(0xFFB91C1C));
    });

    testWidgets('darkTheme has correct brightness and extension', (tester) async {
      final theme = darkTheme();
      expect(theme.brightness, Brightness.dark);
      final palette = theme.extension<VerdictPalette>();
      expect(palette, isNotNull);
      expect(palette!.scam.fg, const Color(0xFFFCA5A5));
    });

    test('VerdictColors.copyWith works', () {
      const colors = VerdictColors(
        bg: Colors.red,
        fg: Colors.white,
        accent: Colors.black,
        soft: Colors.pink,
      );
      final updated = colors.copyWith(bg: Colors.blue);
      expect(updated.bg, Colors.blue);
      expect(updated.fg, Colors.white);
    });

    test('VerdictPalette.copyWith works', () {
      final theme = lightTheme();
      final palette = theme.extension<VerdictPalette>()!;
      final updated = palette.copyWith(scam: palette.safe);
      expect(updated.scam, palette.safe);
      expect(updated.suspicious, palette.suspicious);
    });

    test('VerdictPalette.lerp works', () {
      final themeLight = lightTheme();
      final paletteLight = themeLight.extension<VerdictPalette>()!;
      final themeDark = darkTheme();
      final paletteDark = themeDark.extension<VerdictPalette>()!;
      
      final lerped = paletteLight.lerp(paletteDark, 0.5);
      expect(lerped.scam.bg, Color.lerp(paletteLight.scam.bg, paletteDark.scam.bg, 0.5));
    });
    
    test('VerdictPalette.lerp returns this if other is not VerdictPalette', () {
       final palette = lightTheme().extension<VerdictPalette>()!;
       expect(palette.lerp(null, 0.5), palette);
    });
  });
}
