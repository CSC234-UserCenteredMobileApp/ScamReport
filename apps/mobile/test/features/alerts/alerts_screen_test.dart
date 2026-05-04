import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/alerts/domain/alert.dart';
import 'package:mobile/features/alerts/presentation/alerts_providers.dart';
import 'package:mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:mobile/features/home/domain/recent_alert.dart';
import 'package:mobile/features/sms_scan/domain/sms_alert.dart';
import 'package:mobile/features/sms_scan/presentation/sms_scan_providers.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widget,
  );
}

http.Client _errorClient() {
  return MockClient((_) async => http.Response('error', 500));
}

List<Alert> _fakeAlerts() => [
      Alert(
        id: 'a1',
        title: 'Fake Bank Alert',
        excerpt: 'Scammers impersonate banks.',
        body: '',
        category: AlertCategory.fraudAlert,
        publishedAt: DateTime.utc(2026, 4, 23),
        slug: 'fake-bank-alert',
      ),
      Alert(
        id: 'a2',
        title: 'Quick Safety Tip',
        excerpt: 'Always verify before clicking.',
        body: '',
        category: AlertCategory.tips,
        publishedAt: DateTime.utc(2026, 4, 19),
        slug: 'safety-tip',
      ),
    ];

/// Override that resolves to an empty SMS alert list — avoids hitting drift in tests.
final _emptySmsAlertsOverride = smsAlertsProvider.overrideWith(
  (ref) async => <SmsAlert>[],
);

void main() {
  group('AlertsScreen', () {
    testWidgets('shows loading skeletons before data arrives', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertsProvider.overrideWith(
              (ref) => Future<List<Alert>>.delayed(const Duration(seconds: 30)),
            ),
            _emptySmsAlertsOverride,
          ],
          child: _themed(const AlertsScreen()),
        ),
      );

      await tester.pump();

      // Screen title visible; cards not rendered yet.
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Fake Bank Alert'), findsNothing);
    });

    testWidgets('renders alert cards when data loads', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertsProvider.overrideWith((ref) async => _fakeAlerts()),
            _emptySmsAlertsOverride,
          ],
          child: _themed(const AlertsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fake Bank Alert'), findsOneWidget);
      expect(find.text('Quick Safety Tip'), findsOneWidget);
    });

    testWidgets('shows empty state when list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertsProvider.overrideWith((ref) async => <Alert>[]),
            _emptySmsAlertsOverride,
          ],
          child: _themed(const AlertsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No announcements yet.'), findsOneWidget);
    });

    testWidgets('shows error state when API fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            httpClientProvider.overrideWithValue(_errorClient()),
            _emptySmsAlertsOverride,
          ],
          child: _themed(const AlertsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load — tap to retry'), findsOneWidget);
    });

    testWidgets('filter chip narrows results to matching category',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertsProvider.overrideWith((ref) async => _fakeAlerts()),
            _emptySmsAlertsOverride,
          ],
          child: _themed(const AlertsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Both cards visible with "All" filter active.
      expect(find.text('Fake Bank Alert'), findsOneWidget);
      expect(find.text('Quick Safety Tip'), findsOneWidget);

      // Tap the "Fraud Alert" FilterChip (not the category badge on the card).
      await tester.tap(find.widgetWithText(FilterChip, 'Fraud Alert'));
      await tester.pumpAndSettle();

      // Only fraudAlert card remains.
      expect(find.text('Fake Bank Alert'), findsOneWidget);
      expect(find.text('Quick Safety Tip'), findsNothing);
    });

    testWidgets('SMS Scan filter chip shows sms alerts only', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSmsAlerts = [
        SmsAlert(
          id: 1,
          senderMasked: 'XXXX-1234',
          bodyExcerpt: 'You won a prize!',
          verdict: 'scam',
          detectedAt: DateTime.utc(2026, 4, 25),
          isRead: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertsProvider.overrideWith((ref) async => _fakeAlerts()),
            smsAlertsProvider.overrideWith((ref) async => fakeSmsAlerts),
          ],
          child: _themed(const AlertsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll the chip bar (horizontal ListView) to make "SMS Scan" visible.
      final chipBarScrollable = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(FilterChip, 'SMS Scan'),
        200,
        scrollable: chipBarScrollable,
      );
      await tester.tap(find.widgetWithText(FilterChip, 'SMS Scan'));
      await tester.pumpAndSettle();

      // Only the SMS alert is shown; regular alerts are hidden.
      expect(find.text('XXXX-1234'), findsOneWidget);
      expect(find.text('Fake Bank Alert'), findsNothing);
    });
  });
}
