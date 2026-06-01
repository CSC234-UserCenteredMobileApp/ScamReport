import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/check/domain/matched_scammer.dart';
import 'package:mobile/features/check/presentation/widgets/matched_scammer_card.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(MatchedScammer scammer) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MatchedScammerCard(scammer: scammer),
        ),
      ),
    );

const _full = MatchedScammer(
  summary: ScammerSummary(
    id: 's1',
    displayName: 'Revenue Dept Impersonator',
    suspectedName: 'Revenue Department officer',
    person: ScammerPersonRef(
      id: 'p1',
      fullName: 'John Doe',
      riskLevel: 'high',
      campaignCount: 3,
    ),
    aliases: ['Tax Office', 'Gov Refund'],
    riskLevel: 'high',
    reportCount: 7,
    topScamTypeCodes: ['phone_impersonation', 'phishing_sms'],
  ),
  recentCases: [
    MatchedScammerCase(
      id: 'r1',
      title: 'Fake tax fine call',
      scamTypeCode: 'phone_impersonation',
      verifiedAt: '2026-05-01T10:00:00.000Z',
    ),
    // Null verifiedAt exercises the date-less branch.
    MatchedScammerCase(
      id: 'r2',
      title: 'Refund link SMS',
      scamTypeCode: 'phishing_sms',
    ),
  ],
);

MatchedScammer _minimal(String risk) => MatchedScammer(
      summary: ScammerSummary(
        id: 's2',
        displayName: 'Anonymous campaign',
        aliases: const [],
        riskLevel: risk,
        reportCount: 1,
        topScamTypeCodes: const [],
      ),
      recentCases: const [],
    );

void main() {
  group('MatchedScammerCard', () {
    testWidgets('renders the full profile', (tester) async {
      await tester.pumpWidget(_wrap(_full));
      await tester.pumpAndSettle();

      expect(find.text('Revenue Dept Impersonator'), findsOneWidget);
      expect(find.text('High risk'), findsOneWidget);
      expect(find.text('Claimed to be Revenue Department officer'),
          findsOneWidget);
      expect(find.textContaining('Tax Office'), findsOneWidget);
      expect(find.text('7 linked reports'), findsOneWidget);
      expect(find.text('phone_impersonation'), findsWidgets); // chip
      // Dated case renders "<title> · <date>"; date-less case renders bare.
      expect(find.textContaining('Fake tax fine call'), findsOneWidget);
      expect(find.text('Refund link SMS'), findsOneWidget);
    });

    testWidgets('omits optional sections when empty', (tester) async {
      await tester.pumpWidget(_wrap(_minimal('low')));
      await tester.pumpAndSettle();

      expect(find.text('Anonymous campaign'), findsOneWidget);
      expect(find.text('Low risk'), findsOneWidget);
      expect(find.text('1 linked report'), findsOneWidget);
      expect(find.textContaining('Also known as'), findsNothing);
      expect(find.text('RECENT CASES'), findsNothing);
    });

    testWidgets('maps each risk level to its label', (tester) async {
      for (final entry in const {
        'medium': 'Medium risk',
        'unknown': 'Risk unknown',
      }.entries) {
        await tester.pumpWidget(_wrap(_minimal(entry.key)));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
      }
    });
  });
}
