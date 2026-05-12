import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ask_ai/domain/entities/similar_report.dart';
import 'package:mobile/features/ask_ai/presentation/widgets/similar_report_card.dart';
import 'package:mobile/l10n/l10n.dart';

SimilarReport _fixture({
  String id = 'r-1',
  String title = 'Fake Kerry parcel SMS',
  Object? verifiedAt = const _UseDefault(),
}) {
  final DateTime? resolved = identical(verifiedAt, const _UseDefault())
      ? DateTime.utc(2026, 5, 1)
      : verifiedAt as DateTime?;
  return SimilarReport(
    id: id,
    title: title,
    scamTypeCode: 'phishing_sms',
    scamTypeLabelEn: 'Phishing SMS',
    scamTypeLabelTh: 'ฟิชชิง SMS',
    verifiedAt: resolved,
  );
}

// Sentinel so callers can pass an explicit `null` for verifiedAt without
// the default value overriding it.
class _UseDefault {
  const _UseDefault();
}

Widget _wrap(Widget child,
    {Locale locale = const Locale('en'), GoRouter? router}) {
  final r = router ??
      GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
          GoRoute(
            path: '/report-detail/:id',
            builder: (_, s) => Scaffold(
              body: Text('detail-${s.pathParameters['id']}'),
            ),
          ),
        ],
      );
  return MaterialApp.router(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    routerConfig: r,
  );
}

void main() {
  testWidgets('renders title, English scam-type label, verified date',
      (tester) async {
    await tester.pumpWidget(_wrap(SimilarReportCard(report: _fixture())));
    await tester.pumpAndSettle();

    expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
    expect(find.text('Phishing SMS'), findsOneWidget);
    // Date string is locale-formatted by intl; just assert "Verified" prefix.
    expect(find.textContaining('Verified'), findsOneWidget);
  });

  testWidgets('renders Thai scam-type label when locale is th', (tester) async {
    await tester.pumpWidget(_wrap(
      SimilarReportCard(report: _fixture()),
      locale: const Locale('th'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ฟิชชิง SMS'), findsOneWidget);
  });

  testWidgets('omits date row when verifiedAt is null', (tester) async {
    await tester.pumpWidget(_wrap(
      SimilarReportCard(report: _fixture(verifiedAt: null)),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Verified'), findsNothing);
  });

  testWidgets('tap navigates to /report-detail/:id', (tester) async {
    await tester.pumpWidget(_wrap(SimilarReportCard(report: _fixture(id: 'rep-42'))));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SimilarReportCard));
    await tester.pumpAndSettle();

    expect(find.text('detail-rep-42'), findsOneWidget);
  });
}
