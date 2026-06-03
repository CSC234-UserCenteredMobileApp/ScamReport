// PrivacyScreen is a pure static StatelessWidget: it renders a fixed list of
// LegalSections via LegalDoc. There is no network, repository, provider, or
// auth surface, so there are no loading / error / tap-interaction states to
// exercise. These tests cover what actually exists:
//   - the app bar title
//   - the "Last updated" line
//   - LegalDoc's numbering logic ("${i + 1}. ${heading}") across all sections
//   - body paragraph rendering
//   - that all four sections lay out (SingleChildScrollView builds them all)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/legal/presentation/legal_doc.dart';
import 'package:mobile/features/legal/presentation/privacy_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(Widget widget) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    );

void main() {
  group('PrivacyScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      // Pin the viewport so layout is deterministic across machines.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const PrivacyScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the "Privacy Policy" app bar title', (tester) async {
      await pumpScreen(tester);

      // The title lives inside an AppBar.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Privacy Policy'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the last-updated line', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Last updated: April 25, 2026'), findsOneWidget);
    });

    testWidgets('numbers each section heading via LegalDoc (1..N prefix)',
        (tester) async {
      await pumpScreen(tester);

      // LegalDoc renders each heading as "${i + 1}. ${heading}" in a single
      // Text widget, so the bare heading text never appears on its own.
      expect(find.text('What we collect'), findsNothing);

      // The four privacy sections, in order, each carrying its 1-based index.
      expect(find.text('1. What we collect'), findsOneWidget);
      expect(find.text('2. How we use it'), findsOneWidget);
      expect(find.text('3. Your rights (PDPA)'), findsOneWidget);
      expect(find.text('4. On-device processing'), findsOneWidget);
    });

    testWidgets('renders section body copy', (tester) async {
      await pumpScreen(tester);

      // Body paragraphs render as their own Text widgets.
      expect(
        find.textContaining('Only the extracted identifiers are sent to our'),
        findsOneWidget,
      );
      expect(
        find.textContaining("Under Thailand's PDPA you may request access"),
        findsOneWidget,
      );
    });

    testWidgets('lays out exactly four numbered sections', (tester) async {
      await pumpScreen(tester);

      // Exactly one LegalDoc, and the numbering produces 1..4 — guards against
      // a section being dropped or duplicated.
      expect(find.byType(LegalDoc), findsOneWidget);
      for (final prefix in ['1. ', '2. ', '3. ', '4. ']) {
        expect(find.textContaining(prefix), findsOneWidget);
      }
      // No phantom 5th section.
      expect(find.textContaining('5. '), findsNothing);
    });
  });
}
