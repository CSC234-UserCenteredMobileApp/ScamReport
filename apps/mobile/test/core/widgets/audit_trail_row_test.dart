import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/audit_trail_row.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: widget),
  );
}

void main() {
  group('AuditTrailRow', () {
    testWidgets('renders action label uppercased', (tester) async {
      await tester.pumpWidget(_themed(
        AuditTrailRow(action: 'approve', at: DateTime(2026, 4, 22, 10, 30)),
      ));

      expect(find.textContaining('APPROVE'), findsOneWidget);
    });

    testWidgets('appends admin label when provided', (tester) async {
      await tester.pumpWidget(_themed(
        AuditTrailRow(
          action: 'reject',
          at: DateTime(2026, 4, 22, 10, 30),
          adminLabel: 'admin-7',
        ),
      ));

      expect(find.textContaining('admin-7'), findsOneWidget);
    });

    testWidgets('renders remark when non-empty', (tester) async {
      await tester.pumpWidget(_themed(
        AuditTrailRow(
          action: 'flag',
          at: DateTime(2026, 4, 22, 10, 30),
          remark: 'Need second opinion',
        ),
      ));

      expect(find.text('Need second opinion'), findsOneWidget);
    });

    testWidgets('hides remark line when null or empty', (tester) async {
      await tester.pumpWidget(_themed(
        AuditTrailRow(
          action: 'flag',
          at: DateTime(2026, 4, 22, 10, 30),
        ),
      ));

      // Only action line + timestamp render.
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('formats timestamp', (tester) async {
      await tester.pumpWidget(_themed(
        AuditTrailRow(
          action: 'approve',
          at: DateTime(2026, 4, 22, 10, 30),
        ),
      ));

      // intl DateFormat.yMMMd().add_jm() — match the month name as a sanity
      // check; full string varies by locale lib version.
      expect(find.textContaining('Apr'), findsOneWidget);
    });
  });
}
