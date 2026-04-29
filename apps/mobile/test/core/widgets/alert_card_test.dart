import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/alert_card.dart';
import 'package:mobile/features/home/domain/recent_alert.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: widget)),
  );
}

void main() {
  group('AlertCard', () {
    testWidgets('renders fraudAlert category correctly', (tester) async {
      final alert = RecentAlert(
        id: 'a1',
        title: 'Fraud alert title',
        category: AlertCategory.fraudAlert,
        publishedAt: DateTime(2026, 4, 23),
      );

      await tester.pumpWidget(_themed(AlertCard(alert: alert)));

      expect(find.text('Fraud Alert'), findsOneWidget);
      expect(find.text('Fraud alert title'), findsOneWidget);
      expect(find.text('2026-04-23'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('renders tips category correctly', (tester) async {
      final alert = RecentAlert(
        id: 'a2',
        title: 'Safety tips',
        category: AlertCategory.tips,
        publishedAt: DateTime(2026, 4, 19),
      );

      await tester.pumpWidget(_themed(AlertCard(alert: alert)));

      expect(find.text('Tips'), findsOneWidget);
      expect(find.text('Safety tips'), findsOneWidget);
      expect(find.text('2026-04-19'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('renders platformUpdate category correctly', (tester) async {
      final alert = RecentAlert(
        id: 'a3',
        title: 'Platform update note',
        category: AlertCategory.platformUpdate,
        publishedAt: DateTime(2026, 4, 15),
      );

      await tester.pumpWidget(_themed(AlertCard(alert: alert)));

      expect(find.text('Platform Update'), findsOneWidget);
      expect(find.text('Platform update note'), findsOneWidget);
      expect(find.text('2026-04-15'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
