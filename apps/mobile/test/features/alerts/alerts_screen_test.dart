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
  });
}
