import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/audit_trail_row.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';
import 'package:mobile/features/moderation/domain/mod_repository.dart';
import 'package:mobile/features/moderation/presentation/admin_review_screen.dart';
import 'package:mobile/features/moderation/presentation/mod_providers.dart';
import 'package:mobile/l10n/l10n.dart';

class _RecordingRepository implements ModRepository {
  final List<({String method, String id, String remark})> calls = [];

  @override
  Future<ModQueueData> getQueue() async => const ModQueueData(
        items: [],
        pendingCount: 0,
        flaggedCount: 0,
      );

  @override
  Future<ModReportDetail> getDetail(String reportId) async =>
      throw UnimplementedError();

  @override
  Future<void> approve(String id, String remark) async {
    calls.add((method: 'approve', id: id, remark: remark));
  }

  @override
  Future<void> reject(String id, String remark) async {
    calls.add((method: 'reject', id: id, remark: remark));
  }

  @override
  Future<void> flag(String id, String remark) async {
    calls.add((method: 'flag', id: id, remark: remark));
  }

  @override
  Future<void> unflag(String id, String remark) async {
    calls.add((method: 'unflag', id: id, remark: remark));
  }
}

ModReportDetail _detail({
  String status = 'pending',
  int? aiScore,
  String? aiConfidence,
  List<EvidenceFile> evidenceFiles = const [],
  List<ModerationAction> auditTrail = const [],
  String? targetIdentifier,
}) =>
    ModReportDetail(
      id: 'r1',
      title: 'Fake Kerry parcel SMS',
      scamTypeCode: 'phishing_sms',
      scamTypeLabelEn: 'Phishing SMS',
      scamTypeLabelTh: 'ฟิชชิง SMS',
      submittedAt: DateTime.utc(2026, 4, 22, 10),
      status: status,
      priorityFlag: status == 'flagged',
      evidenceCount: evidenceFiles.length,
      description: 'Detailed description of the scam.',
      targetIdentifier: targetIdentifier,
      targetIdentifierKind: targetIdentifier == null ? null : 'url',
      evidenceFiles: evidenceFiles,
      duplicateCount: 0,
      auditTrail: auditTrail,
      aiScore: aiScore,
      aiConfidence: aiConfidence,
    );

Widget _wrap(
  Widget widget, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, __) => widget)],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: router,
    ),
  );
}

void main() {
  group('AdminReviewScreen', () {
    testWidgets('renders title, description, English scam-type label', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
      expect(find.text('Detailed description of the scam.'), findsOneWidget);
      expect(find.text('Phishing SMS'), findsOneWidget);
    });

    testWidgets('renders Thai scam-type label when locale is th', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
        locale: const Locale('th'),
      ));

      await tester.pumpAndSettle();

      expect(find.text('ฟิชชิง SMS'), findsOneWidget);
    });

    testWidgets('never renders reporter identity (FR-7.4 anti-regression)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('User_'), findsNothing);
      expect(find.textContaining('Submitted by'), findsNothing);
      expect(find.textContaining('@user'), findsNothing);
    });

    testWidgets('shows date-only "Submitted" line', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      // Match by prefix; the date string itself is locale-formatted by intl.
      expect(find.textContaining('Submitted '), findsOneWidget);
    });

    testWidgets('AI score row visible when score is non-null', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async =>
              _detail(aiScore: 87, aiConfidence: 'high')),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('87%'), findsOneWidget);
    });

    testWidgets('AI score row hidden when score is null', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('confidence'), findsNothing);
    });

    testWidgets('renders no-evidence placeholder when list is empty',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('No evidence files.'), findsOneWidget);
    });

    testWidgets('audit trail renders one AuditTrailRow per record',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail(
                auditTrail: [
                  ModerationAction(
                    action: 'flag',
                    remark: 'team review',
                    createdAt: DateTime.utc(2026, 4, 23, 9),
                  ),
                  ModerationAction(
                    action: 'unflag',
                    remark: 'resolved',
                    createdAt: DateTime.utc(2026, 4, 23, 12),
                  ),
                ],
              )),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.byType(AuditTrailRow), findsNWidgets(2));
    });

    testWidgets('audit trail empty placeholder when list is empty',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('No actions yet.'), findsOneWidget);
    });

    testWidgets('action bar shows Reject / Flag / Approve when pending',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Flag'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Unflag'), findsNothing);
    });

    testWidgets('action bar swaps Flag for Unflag when status flagged',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith(
              (ref) async => _detail(status: 'flagged')),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Unflag'), findsOneWidget);
      expect(find.text('Flag'), findsNothing);
    });

    testWidgets('approve flow opens dialog, requires non-empty remark, and calls repo',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _RecordingRepository();

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
          modRepositoryProvider.overrideWithValue(repo),
        ],
      ));

      await tester.pumpAndSettle();

      // Tap Approve in the action bar (the FilledButton, not the dialog
      // version which doesn't exist yet).
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();

      // Dialog open. Tap the dialog's Approve with empty input — must not
      // dismiss (the implementation pops only when text is non-empty).
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);

      // Now type a remark and submit.
      await tester.enterText(find.byType(TextField), 'looks legit');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.first.method, 'approve');
      expect(repo.calls.first.id, 'r1');
      expect(repo.calls.first.remark, 'looks legit');
    });

    testWidgets('reject flow calls repo.reject', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _RecordingRepository();

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
          modRepositoryProvider.overrideWithValue(repo),
        ],
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'spam');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(repo.calls.single.method, 'reject');
      expect(repo.calls.single.remark, 'spam');
    });

    testWidgets('flag flow calls repo.flag', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _RecordingRepository();

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
          modRepositoryProvider.overrideWithValue(repo),
        ],
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Flag'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'team review');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Flag'));
      await tester.pumpAndSettle();

      expect(repo.calls.single.method, 'flag');
      expect(repo.calls.single.remark, 'team review');
    });

    testWidgets('unflag flow calls repo.unflag when already flagged',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _RecordingRepository();

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith(
              (ref) async => _detail(status: 'flagged')),
          modRepositoryProvider.overrideWithValue(repo),
        ],
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Unflag'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'resolved');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Unflag'));
      await tester.pumpAndSettle();

      expect(repo.calls.single.method, 'unflag');
      expect(repo.calls.single.remark, 'resolved');
    });

    testWidgets('cancel button uses localised label', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith((ref) async => _detail()),
          modRepositoryProvider.overrideWithValue(_RecordingRepository()),
        ],
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();

      // Localised "Cancel" exists in the dialog; raw `const Text('Cancel')`
      // would also pass, so the deeper guarantee is that this string is in
      // the ARB. Smoke check that the dialog button is reachable.
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('shows error state when fetch fails', (tester) async {
      await tester.pumpWidget(_wrap(
        const AdminReviewScreen(reportId: 'r1'),
        overrides: [
          modDetailProvider('r1').overrideWith(
            (ref) => Future<ModReportDetail>.error(Exception('network')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Exception'), findsOneWidget);
    });
  });
}
