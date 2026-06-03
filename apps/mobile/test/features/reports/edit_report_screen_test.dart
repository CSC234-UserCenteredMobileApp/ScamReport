// Widget tests for EditReportScreen.
//
// Data dependencies (see edit_report_screen.dart):
//  - editReportDetailProvider(reportId) — FutureProvider.family<EditReportDetail>
//  - editScamTypesProvider — FutureProvider<List<ScamTypeOption>>
//  - reportsRepositoryProvider — used by _save() (updateReport / uploadEvidence)
//  - myReportsProvider — invalidated after save
//
// We override the two FutureProviders directly and mock the repository with
// mocktail. This keeps the real repo/API (and thus firebaseAuthProvider, which
// is NOT initialised in tests) out of the picture entirely.
//
// Note the screen's `_initialized` post-frame gate: when detail data first
// arrives it schedules an addPostFrameCallback to fill the controllers, and the
// very first build still shows the loading skeleton. So loaded/save tests must
// pumpAndSettle (not a single pump) before the form renders.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/reports/data/reports_repository.dart';
import 'package:mobile/features/reports/domain/edit_report_detail.dart';
import 'package:mobile/features/reports/domain/my_report.dart';
import 'package:mobile/features/reports/presentation/edit_report_providers.dart';
import 'package:mobile/features/reports/presentation/edit_report_screen.dart';
import 'package:mobile/l10n/l10n.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

const _reportId = 'rep-1';

EditReportDetail _detail({List<ExistingEvidenceFile> evidence = const []}) {
  return EditReportDetail(
    id: _reportId,
    title: 'Fake bank OTP SMS',
    description: 'Pretends to be my bank and asks for an OTP code.',
    scamTypeCode: 'phishing_sms',
    scamTypeLabelEn: 'Phishing SMS',
    scamTypeLabelTh: 'Phishing SMS',
    status: 'pending',
    targetIdentifier: '+66812345678',
    targetIdentifierKind: 'phone',
    evidenceFiles: evidence,
  );
}

const _scamTypes = [
  ScamTypeOption(
    code: 'phishing_sms',
    labelEn: 'Phishing SMS',
    labelTh: 'Phishing SMS',
  ),
  ScamTypeOption(
    code: 'fake_qr',
    labelEn: 'Fake QR',
    labelTh: 'Fake QR',
  ),
];

/// Builds a 2-page router stack so `context.pop()` in _save returns to `/`
/// instead of asserting "popped the last page".
Widget _wrap({required List<Override> overrides}) {
  final router = GoRouter(
    initialLocation: '/edit',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home-after-pop')),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, __) => const EditReportScreen(reportId: _reportId),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  late MockReportsRepository repo;

  setUp(() {
    repo = MockReportsRepository();
    when(() => repo.getMyReports()).thenAnswer((_) async => <MyReport>[]);
    when(
      () => repo.updateReport(
        reportId: any(named: 'reportId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        scamTypeCode: any(named: 'scamTypeCode'),
        targetIdentifier: any(named: 'targetIdentifier'),
        targetIdentifierKind: any(named: 'targetIdentifierKind'),
        evidenceFiles: any(named: 'evidenceFiles'),
      ),
    ).thenAnswer((_) async {});
  });

  void pinViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows loading skeleton while the report detail is in flight',
      (tester) async {
    pinViewport(tester);

    await tester.pumpWidget(
      _wrap(
        overrides: [
          // A never-completing future leaves the provider in loading state
          // with no pending timer at teardown.
          editReportDetailProvider(_reportId).overrideWith(
            (ref) => Completer<EditReportDetail>().future,
          ),
          editScamTypesProvider.overrideWith((ref) async => _scamTypes),
          reportsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );

    // Single pump — provider still loading.
    await tester.pump();

    // The edit form is not built yet; no real field labels, no Save button.
    expect(find.text('Fake bank OTP SMS'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    // Pin this as the LOADING state (not the error state) — the error body
    // would also satisfy the two absence checks above.
    expect(find.text('Could not load report.'), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('renders the prefilled form once detail data loads',
      (tester) async {
    pinViewport(tester);

    await tester.pumpWidget(
      _wrap(
        overrides: [
          editReportDetailProvider(_reportId)
              .overrideWith((ref) async => _detail()),
          editScamTypesProvider.overrideWith((ref) async => _scamTypes),
          reportsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );

    // pumpAndSettle to flush the post-frame _initialized callback that fills
    // the controllers and swaps the skeleton for the real form.
    await tester.pumpAndSettle();

    // Title controller pre-populated from the detail.
    expect(find.text('Fake bank OTP SMS'), findsOneWidget);
    expect(
      find.text('Pretends to be my bank and asks for an OTP code.'),
      findsOneWidget,
    );
    // Identifier prefilled.
    expect(find.text('+66812345678'), findsOneWidget);
    // Save button present and enabled (scamType is set => canSave true).
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
  });

  testWidgets('shows the error body with a Retry button when detail fails',
      (tester) async {
    pinViewport(tester);

    await tester.pumpWidget(
      _wrap(
        overrides: [
          editReportDetailProvider(_reportId).overrideWith(
            (ref) async => throw Exception('boom'),
          ),
          editScamTypesProvider.overrideWith((ref) async => _scamTypes),
          reportsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Could not load report.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    // The form must not be present in the error state.
    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
  });

  testWidgets('tapping Save calls updateReport with the edited fields',
      (tester) async {
    pinViewport(tester);

    await tester.pumpWidget(
      _wrap(
        overrides: [
          editReportDetailProvider(_reportId)
              .overrideWith((ref) async => _detail()),
          editScamTypesProvider.overrideWith((ref) async => _scamTypes),
          reportsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Edit the title before saving.
    await tester.enterText(
      find.widgetWithText(TextField, 'Fake bank OTP SMS'),
      'Edited title',
    );
    await tester.pump();

    // Save sits below the fold at this viewport; bring it on-screen first.
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Assert via the mock (snackbar races with the immediate context.pop()).
    final captured = verify(
      () => repo.updateReport(
        reportId: captureAny(named: 'reportId'),
        title: captureAny(named: 'title'),
        description: any(named: 'description'),
        scamTypeCode: captureAny(named: 'scamTypeCode'),
        targetIdentifier: any(named: 'targetIdentifier'),
        targetIdentifierKind: any(named: 'targetIdentifierKind'),
        evidenceFiles: any(named: 'evidenceFiles'),
      ),
    ).captured;

    expect(captured[0], _reportId); // reportId
    expect(captured[1], 'Edited title'); // trimmed new title
    expect(captured[2], 'phishing_sms'); // scamTypeCode preserved

    // Navigation popped back to home after a successful save.
    expect(find.text('home-after-pop'), findsOneWidget);
  });

  testWidgets('shows save-failed snackbar when updateReport throws',
      (tester) async {
    pinViewport(tester);

    when(
      () => repo.updateReport(
        reportId: any(named: 'reportId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        scamTypeCode: any(named: 'scamTypeCode'),
        targetIdentifier: any(named: 'targetIdentifier'),
        targetIdentifierKind: any(named: 'targetIdentifierKind'),
        evidenceFiles: any(named: 'evidenceFiles'),
      ),
    ).thenThrow(Exception('network down'));

    await tester.pumpWidget(
      _wrap(
        overrides: [
          editReportDetailProvider(_reportId)
              .overrideWith((ref) async => _detail()),
          editScamTypesProvider.overrideWith((ref) async => _scamTypes),
          reportsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump(); // let the failure snackbar render

    expect(
      find.text('Could not update report. Please try again.'),
      findsOneWidget,
    );
    // Still on the edit screen (no pop on failure).
    expect(find.text('home-after-pop'), findsNothing);
  });
}
