// Widget tests for PlatformSummaryScreen.
//
// The screen renders a single FutureProvider (`platformSummaryProvider`) via
// `AsyncValue.when`, so the tests drive its three branches directly:
//  - loading  -> CircularProgressIndicator
//  - data     -> section cards (totals / scam-type / check-logs)
//  - error    -> the error message text
// Plus the empty-data branch (`if (rows.isEmpty) return Text('No data.')`)
// which is the only other widget-level branching on this screen.
//
// The PDF-export action is intentionally not exercised: its onPressed calls
// `Printing.layoutPdf`, which hits a MethodChannel with no test handler and
// would throw a MissingPluginException inside a fire-and-forget closure.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/platform_summary/domain/platform_summary.dart';
import 'package:mobile/features/platform_summary/presentation/platform_summary_providers.dart';
import 'package:mobile/features/platform_summary/presentation/platform_summary_screen.dart';
import 'package:mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget widget, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
}

PlatformSummary _summary({
  List<PlatformScamType> scamTypes = const [],
  List<PlatformTopScammer> scammers = const [],
  List<PlatformTopIdentifier> identifiers = const [],
}) {
  return PlatformSummary(
    range: PlatformSummaryRange(
      from: DateTime.utc(2026, 4, 1),
      to: DateTime.utc(2026, 4, 30),
    ),
    reports: const PlatformReportTotals(
      total: 512,
      verified: 300,
      pending: 120,
      rejected: 50,
      flagged: 42,
    ),
    scamTypeBreakdown: scamTypes,
    topScammers: scammers,
    topIdentifiers: identifiers,
    checkLogs: const PlatformCheckLogs(
      total: 1024,
      verdictMix: PlatformVerdictMix(
        scam: 400,
        suspicious: 300,
        safe: 224,
        unknown: 100,
      ),
    ),
    generatedAt: DateTime.utc(2026, 4, 30, 12),
  );
}

PlatformSummary _populatedSummary() => _summary(
      scamTypes: const [
        PlatformScamType(
          scamTypeCode: 'phishing_sms',
          labelEn: 'Phishing SMS',
          count: 88,
        ),
        PlatformScamType(
          scamTypeCode: 'fake_qr',
          labelEn: 'Fake QR',
          count: 33,
        ),
      ],
      scammers: const [
        PlatformTopScammer(
          id: 's1',
          displayName: 'Mr. Scam',
          suspectedName: 'Alias One',
          reportCount: 17,
          riskLevel: 'high',
        ),
      ],
      identifiers: const [
        PlatformTopIdentifier(
          kind: 'phone',
          valueNormalized: '+66844192270',
          reportCount: 9,
        ),
      ],
    );

void _pinViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('PlatformSummaryScreen', () {
    testWidgets('shows a loading spinner while the summary is pending',
        (tester) async {
      _pinViewport(tester);

      // A future that never completes -> stays in the loading branch with no
      // pending Timer to trip the teardown checker.
      final completer = Completer<PlatformSummary>();
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(_populatedSummary());
      });

      await tester.pumpWidget(
        _wrap(
          const PlatformSummaryScreen(),
          overrides: [
            platformSummaryProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The title is always present from the AppBar.
      expect(find.text('Platform summary'), findsOneWidget);
    });

    // BLOCKED BY PRODUCTION BUG (not flaky): every data-branch test below
    // currently fails because _ReportTotals.build returns Expanded() cells
    // parented to SizedBox/Wrap (no Flex ancestor) -> "Incorrect use of
    // ParentDataWidget" assertion. These tests assert the CORRECT behavior and
    // are the regression guard; they go green once the screen is fixed. See
    // the QA report's notes. Do NOT skip or swallow the exception to pass.
    testWidgets('renders the report totals and section cards on success',
        (tester) async {
      _pinViewport(tester);

      await tester.pumpWidget(
        _wrap(
          const PlatformSummaryScreen(),
          overrides: [
            platformSummaryProvider
                .overrideWith((ref) async => _populatedSummary()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Section heading (uppercased by _Section) plus a report total value.
      expect(find.text('REPORTS'), findsOneWidget);
      expect(find.text('512'), findsOneWidget); // total
      expect(find.text('300'), findsOneWidget); // verified

      // Scam-type breakdown label is rendered (top of the list, in viewport).
      expect(find.text('SCAM-TYPE BREAKDOWN'), findsOneWidget);
      expect(find.text('Phishing SMS'), findsOneWidget);

      // No loading / error artefacts remain.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('lower sections become visible after scrolling',
        (tester) async {
      _pinViewport(tester);

      await tester.pumpWidget(
        _wrap(
          const PlatformSummaryScreen(),
          overrides: [
            platformSummaryProvider
                .overrideWith((ref) async => _populatedSummary()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The check-logs card sits at the bottom of the lazy ListView and is not
      // built at this viewport until scrolled into range.
      await tester.scrollUntilVisible(
        find.text('Total calls: 1024'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Total calls: 1024'), findsOneWidget);
      expect(find.text('Scam: 400'), findsOneWidget);
    });

    testWidgets('shows the error message when the summary fails to load',
        (tester) async {
      _pinViewport(tester);

      await tester.pumpWidget(
        _wrap(
          const PlatformSummaryScreen(),
          overrides: [
            platformSummaryProvider.overrideWith(
              (ref) async => throw Exception('boom'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // _Body is never built; the error branch shows e.toString().
      expect(find.textContaining('boom'), findsOneWidget);
      expect(find.text('REPORTS'), findsNothing);
    });

    testWidgets('renders "No data." placeholders for empty breakdown lists',
        (tester) async {
      _pinViewport(tester);

      await tester.pumpWidget(
        _wrap(
          const PlatformSummaryScreen(),
          overrides: [
            // All three list sections empty -> three "No data." texts. Empty
            // cards are short, so all sections fit without scrolling.
            platformSummaryProvider.overrideWith((ref) async => _summary()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data.'), findsNWidgets(3));
      // Totals still render even when the breakdown lists are empty.
      expect(find.text('512'), findsOneWidget);
    });
  });
}
