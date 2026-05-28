// Golden test for VerdictPill — visual-regression evidence for the CSC234
// D4 deliverable. Renders all four verdict states (scam / suspicious / safe /
// unknown) so a single image proves the VerdictPalette ThemeExtension and
// the icon mapping remain stable.
//
// Uses a minimal inline ThemeData (no GoogleFonts) so the test runs offline
// on CI. The production app's `lightTheme()` is exercised elsewhere by
// non-golden widget tests.
//
// Regenerate with:
//   cd apps/mobile && flutter test --update-goldens \
//     test/widgets/verdict_pill_golden_test.dart
//
// Generated PNG lives next to this file under goldens/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/verdict_pill.dart';
import 'package:mobile/l10n/l10n.dart';

const _kVerdicts = <String>['scam', 'suspicious', 'safe', 'unknown'];

const _scamLight = VerdictColors(
  bg: Color(0xFFFEF2F2),
  fg: Color(0xFFB91C1C),
  accent: Color(0xFFDC2626),
  soft: Color(0xFFFEE2E2),
);
const _suspiciousLight = VerdictColors(
  bg: Color(0xFFFFFBEB),
  fg: Color(0xFFB45309),
  accent: Color(0xFFF59E0B),
  soft: Color(0xFFFEF3C7),
);
const _safeLight = VerdictColors(
  bg: Color(0xFFF0FDF4),
  fg: Color(0xFF15803D),
  accent: Color(0xFF16A34A),
  soft: Color(0xFFDCFCE7),
);
const _unknownLight = VerdictColors(
  bg: Color(0xFFF8FAFC),
  fg: Color(0xFF475569),
  accent: Color(0xFF64748B),
  soft: Color(0xFFE2E8F0),
);

ThemeData _testTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[
      VerdictPalette(
        scam: _scamLight,
        suspicious: _suspiciousLight,
        safe: _safeLight,
        unknown: _unknownLight,
      ),
    ],
  );
}

Widget _strip() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _testTheme(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (final v in _kVerdicts) VerdictPill(verdict: v),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('VerdictPill — all four states', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    await tester.pumpWidget(_strip());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verdict_pill_light.png'),
    );
  });
}
