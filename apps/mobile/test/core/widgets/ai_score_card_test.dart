import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/ai_score_palette.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/ai_score_card.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AiScoreCard', () {
    testWidgets('renders pending chip for full variant when score is null',
        (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(score: null, confidence: null),
      ));
      // No score ring, no RISK label — the admin sees a muted placeholder.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('RISK'), findsNothing);
      expect(find.text('AI score pending'), findsOneWidget);
    });

    testWidgets('compact variant renders nothing when score is null',
        (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(
          score: null,
          confidence: null,
          variant: AiScoreCardVariant.compact,
        ),
      ));
      expect(find.text('AI score pending'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders full card with score ring + verdict label',
        (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(
          score: 87,
          confidence: 'high',
          variant: AiScoreCardVariant.full,
        ),
      ));
      expect(find.text('87'), findsOneWidget);
      expect(find.text('AI VERDICT'), findsOneWidget);
      expect(find.text('Likely scam'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('compact variant shows score number + AI label',
        (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(
          score: 64,
          confidence: 'medium',
          variant: AiScoreCardVariant.compact,
        ),
      ));
      expect(find.text('64'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      // Full-card verdict label must NOT appear in compact.
      expect(find.text('AI VERDICT'), findsNothing);
    });

    testWidgets('exposes accessible label via Semantics', (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(score: 75, confidence: 'medium'),
      ));
      final semantics = tester.getSemantics(find.byType(AiScoreCard));
      expect(semantics.label, contains('75'));
      expect(semantics.label, contains('medium'));
    });

    testWidgets('renders unknown verdict copy for unknown confidence',
        (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(
          score: 30,
          confidence: 'unknown',
          variant: AiScoreCardVariant.full,
        ),
      ));
      expect(find.text('Inconclusive'), findsOneWidget);
    });

    testWidgets('renders nothing when palette resolution returns null',
        (tester) async {
      // No VerdictPalette extension installed → forConfidence returns null.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AiScoreCard(score: 50, confidence: 'low'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders Thai verdict copy when locale is th', (tester) async {
      await tester.pumpWidget(_themed(
        const AiScoreCard(
          score: 92,
          confidence: 'high',
          variant: AiScoreCardVariant.full,
        ),
        locale: const Locale('th'),
      ));
      expect(find.text('น่าจะเป็นสแกม'), findsOneWidget);
      expect(find.text('ผลตรวจ AI'), findsOneWidget);
    });
  });

  group('AiScorePalette', () {
    testWidgets('high maps to safe tones', (tester) async {
      late Color color;
      await tester.pumpWidget(_themed(
        Builder(builder: (context) {
          color = AiScorePalette.forConfidence(context, 'high')!.fg;
          return const SizedBox();
        }),
      ));
      expect(color, isNotNull);
    });

    testWidgets('null confidence yields null bundle', (tester) async {
      late dynamic result;
      await tester.pumpWidget(_themed(
        Builder(builder: (context) {
          result = AiScorePalette.forConfidence(context, null);
          return const SizedBox();
        }),
      ));
      expect(result, isNull);
    });

    testWidgets('unrecognised confidence falls back to unknown bundle',
        (tester) async {
      late dynamic result;
      await tester.pumpWidget(_themed(
        Builder(builder: (context) {
          result = AiScorePalette.forConfidence(context, 'bogus');
          return const SizedBox();
        }),
      ));
      expect(result, isNotNull);
    });
  });
}
