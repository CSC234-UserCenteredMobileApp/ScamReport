// Golden test for SectionHeader — proves the uppercase-label + letter-spacing
// styling stays stable. No `onSeeAll` callback so the widget avoids the l10n
// 'See all' lookup and stays deterministic across locales.
//
// Uses a minimal inline ThemeData (no GoogleFonts) so the test runs offline
// on CI.
//
// Regenerate with:
//   cd apps/mobile && flutter test --update-goldens \
//     test/widgets/section_header_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/section_header.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _frame() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: SectionHeader(title: 'Recent alerts'),
      ),
    ),
  );
}

void main() {
  testWidgets('SectionHeader — title only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 120));
    await tester.pumpWidget(_frame());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/section_header_light.png'),
    );
  });
}
