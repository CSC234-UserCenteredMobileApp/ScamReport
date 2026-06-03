// Behavioral widget tests for MyReportsScreen.
//
// The screen reads `myReportsProvider` (a FutureProvider that flows through
// `reportsRepositoryProvider.getMyReports()`) for the list, and calls
// `reportsRepositoryProvider.withdrawReport()` on the withdraw confirm path.
// We mock the repository with mocktail and override the single provider, which
// drives every async state (data / loading / error) plus the withdraw mutation.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/reports/data/reports_repository.dart';
import 'package:mobile/features/reports/domain/my_report.dart';
import 'package:mobile/features/reports/presentation/my_reports_providers.dart';
import 'package:mobile/features/reports/presentation/my_reports_screen.dart';
import 'package:mobile/l10n/l10n.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

MyReport _report({
  required String id,
  required String title,
  required MyReportStatus status,
  String? rejectionRemark,
}) {
  final now = DateTime(2026, 5, 1, 12);
  return MyReport(
    id: id,
    title: title,
    scamTypeCode: 'phishing_sms',
    scamTypeLabelEn: 'Phishing SMS',
    scamTypeLabelTh: 'Phishing SMS',
    status: status,
    createdAt: now,
    updatedAt: now,
    rejectionRemark: rejectionRemark,
  );
}

final _mixedReports = <MyReport>[
  _report(
    id: 'r1',
    title: 'Fake Grab promo phishing',
    status: MyReportStatus.pending,
  ),
  _report(
    id: 'r2',
    title: 'QR code swap at ATM',
    status: MyReportStatus.verified,
  ),
  _report(
    id: 'r3',
    title: 'Bogus tax refund call',
    status: MyReportStatus.rejected,
    rejectionRemark: 'Not enough evidence',
  ),
];

/// Wraps [MyReportsScreen] in a GoRouter so the screen's navigation triggers
/// (`context.push`, `context.go`, `context.canPop`) resolve against real routes.
Widget _wrap(MockReportsRepository repo) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const MyReportsScreen()),
      GoRoute(
        path: '/edit-report/:id',
        builder: (_, __) => const Scaffold(body: Text('edit-report-route')),
      ),
      GoRoute(
        path: '/report-detail/:id',
        builder: (_, __) => const Scaffold(body: Text('report-detail-route')),
      ),
      GoRoute(
        path: '/ask-ai',
        builder: (_, __) => const Scaffold(body: Text('ask-ai-route')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      reportsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(''));

  late MockReportsRepository repo;

  setUp(() {
    repo = MockReportsRepository();
  });

  void pinViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renders a row per report when data loads', (tester) async {
    pinViewport(tester);
    when(() => repo.getMyReports()).thenAnswer((_) async => _mixedReports);

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Fake Grab promo phishing'), findsOneWidget);
    expect(find.text('QR code swap at ATM'), findsOneWidget);
    expect(find.text('Bogus tax refund call'), findsOneWidget);
    // Rejected report surfaces the moderator note.
    expect(
      find.textContaining('Not enough evidence'),
      findsOneWidget,
    );
  });

  testWidgets('shows the skeleton (no rows, no filter chips) while loading',
      (tester) async {
    pinViewport(tester);
    // Never-completing future keeps the provider in the loading state.
    final completer = Completer<List<MyReport>>();
    when(() => repo.getMyReports()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(repo));
    // Single pump: providers are loading, no data resolved.
    await tester.pump();

    expect(find.text('Fake Grab promo phishing'), findsNothing);
    // The filter bar is SizedBox.shrink while the list is loading.
    expect(find.byType(FilterChip), findsNothing);

    // Resolve so no pending timers/futures leak past the test.
    completer.complete(const <MyReport>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows error message + Retry when the load fails',
      (tester) async {
    pinViewport(tester);
    when(() => repo.getMyReports()).thenThrow(Exception('boom'));

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // _ErrorBody renders e.toString().
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('tapping a status filter chip narrows the visible list',
      (tester) async {
    pinViewport(tester);
    when(() => repo.getMyReports()).thenAnswer((_) async => _mixedReports);

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // All three statuses visible under the default "All" filter.
    expect(find.text('Fake Grab promo phishing'), findsOneWidget);
    expect(find.text('QR code swap at ATM'), findsOneWidget);

    // Filter to Verified-only (count is 1 so the chip renders).
    await tester.tap(find.widgetWithText(FilterChip, 'Verified (1)'));
    await tester.pumpAndSettle();

    expect(find.text('QR code swap at ATM'), findsOneWidget);
    expect(find.text('Fake Grab promo phishing'), findsNothing);
    expect(find.text('Bogus tax refund call'), findsNothing);
  });

  testWidgets('confirming the withdraw dialog calls withdrawReport',
      (tester) async {
    pinViewport(tester);
    when(() => repo.getMyReports()).thenAnswer((_) async => _mixedReports);
    when(() => repo.withdrawReport(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // The "Withdraw" row action only renders on pending rows (r1).
    await tester.tap(find.widgetWithText(OutlinedButton, 'Withdraw'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears.
    expect(find.text('Withdraw report?'), findsOneWidget);

    // Confirm via the dialog's FilledButton (the row button is an OutlinedButton).
    await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
    await tester.pumpAndSettle();

    verify(() => repo.withdrawReport('r1')).called(1);
  });

  testWidgets('dismissing the withdraw dialog does NOT withdraw',
      (tester) async {
    pinViewport(tester);
    when(() => repo.getMyReports()).thenAnswer((_) async => _mixedReports);
    when(() => repo.withdrawReport(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Withdraw'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw report?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Withdraw report?'), findsNothing);
    verifyNever(() => repo.withdrawReport(any()));
  });
}
