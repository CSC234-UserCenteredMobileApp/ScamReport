import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/report_card.dart';
import 'package:mobile/features/home/domain/recent_report.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: ThemeData(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: widget),
  );
}

void main() {
  final testReport = RecentReport(
    id: 'r1',
    title: 'Phishing Scam',
    excerpt: 'This is a phishing scam excerpt.',
    scamTypeCode: 'phishing_sms',
    scamTypeLabelEn: 'Phishing SMS',
    scamTypeLabelTh: 'ข้อความหลอกลวง',
    verifiedAt: DateTime(2026, 4, 20),
    reportCount: 14,
  );

  group('ReportCard', () {
    testWidgets('renders report information in English', (tester) async {
      await tester.pumpWidget(_themed(ReportCard(report: testReport)));

      expect(find.text('Phishing SMS'), findsOneWidget);
      expect(find.text('Phishing Scam'), findsOneWidget);
      expect(find.text('This is a phishing scam excerpt.'), findsOneWidget);
      expect(find.text('04-20'), findsOneWidget);
      // Localization for report count
      expect(find.text('14 reports'), findsOneWidget);
    });

    testWidgets('renders report information in Thai', (tester) async {
      await tester.pumpWidget(
        _themed(ReportCard(report: testReport), locale: const Locale('th')),
      );

      expect(find.text('ข้อความหลอกลวง'), findsOneWidget);
      expect(find.text('Phishing Scam'), findsOneWidget);
      expect(find.text('04-20'), findsOneWidget);
      // Thai localization for report count
      expect(find.text('14 รายงาน'), findsOneWidget);
    });
  });
}
