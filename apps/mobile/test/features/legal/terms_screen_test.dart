// Behavioural widget tests for the Terms of Service screen.
//
// TermsScreen is a static StatelessWidget: it has no providers, network,
// auth, or navigation. The meaningful behaviour is delegated to LegalDoc,
// which renders a "Last updated" line plus a numbered list of sections
// (`${i + 1}. ${heading}`). These tests pin that rendering contract:
//  - the AppBar title,
//  - the last-updated metadata line,
//  - every section heading WITH its 1-based number prefix (the LegalDoc loop),
//  - at least one section body,
//  - the document order of the sections.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/legal/presentation/terms_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(Widget widget) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    );

void main() {
  group('TermsScreen', () {
    testWidgets('renders the AppBar title', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const TermsScreen()));
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Terms of Service'), findsOneWidget);
    });

    testWidgets('renders the last-updated metadata line', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const TermsScreen()));
      await tester.pump();

      expect(find.text('Last updated: April 25, 2026'), findsOneWidget);
    });

    testWidgets('renders all four section headings with their number prefix',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const TermsScreen()));
      await tester.pump();

      // LegalDoc renders "${i + 1}. ${heading}" as one Text node, so the
      // numbering prefix must be part of the match — this pins the loop.
      expect(find.text('1. Eligibility'), findsOneWidget);
      expect(find.text('2. Acceptable use'), findsOneWidget);
      expect(find.text('3. Content ownership'), findsOneWidget);
      expect(find.text('4. Termination'), findsOneWidget);
    });

    testWidgets('renders a section body', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const TermsScreen()));
      await tester.pump();

      // Bodies are long concatenated literals; match a distinctive substring.
      expect(
        find.textContaining('at least 13 years old'),
        findsOneWidget,
      );
      expect(
        find.textContaining('suspend or delete accounts'),
        findsOneWidget,
      );
    });

    testWidgets('sections render in document order', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const TermsScreen()));
      await tester.pump();

      // SingleChildScrollView + Column lays out every child regardless of the
      // viewport, so all headings have a deterministic vertical position.
      final y1 = tester.getTopLeft(find.text('1. Eligibility')).dy;
      final y2 = tester.getTopLeft(find.text('2. Acceptable use')).dy;
      final y3 = tester.getTopLeft(find.text('3. Content ownership')).dy;
      final y4 = tester.getTopLeft(find.text('4. Termination')).dy;

      expect(y1 < y2, isTrue);
      expect(y2 < y3, isTrue);
      expect(y3 < y4, isTrue);
    });
  });
}
