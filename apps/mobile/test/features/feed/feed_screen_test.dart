import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/feed/presentation/feed_providers.dart';
import 'package:mobile/features/feed/presentation/feed_screen.dart';
import 'package:mobile/features/home/domain/home_stats.dart';
import 'package:mobile/features/home/domain/recent_report.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: widget,
  );
}

http.Client _happyClient() {
  return MockClient((request) async {
    if (request.url.path == '/stats') {
      return http.Response(
        jsonEncode({
          'data': {
            'verifiedTotal': 2184,
            'newThisWeek': 28,
            'topScamTypeLabelEn': 'SMS phishing',
            'topScamTypeLabelTh': 'SMS phishing',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path == '/reports') {
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'r1',
              'title': 'Fake Kerry parcel SMS',
              'excerpt': 'Phishing link in parcel SMS.',
              'scamTypeCode': 'phishing_sms',
              'scamTypeLabelEn': 'Phishing SMS',
              'scamTypeLabelTh': 'SMS หลอกลวง',
              'verifiedAt': '2026-05-01T00:00:00.000Z',
              'reportCount': 3,
            },
            {
              'id': 'r2',
              'title': 'Caller pretending Revenue Department',
              'excerpt': 'Demands transfer for fake tax penalties.',
              'scamTypeCode': 'phone_impersonation',
              'scamTypeLabelEn': 'Phone impersonation',
              'scamTypeLabelTh': 'แอบอ้างทางโทรศัพท์',
              'verifiedAt': '2026-04-30T00:00:00.000Z',
              'reportCount': 2,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('not found', 404);
  });
}

http.Client _errorClient() =>
    MockClient((_) async => http.Response('server error', 500));

void main() {
  group('FeedScreen', () {
    testWidgets('renders title, stats, filter chips, and report cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [httpClientProvider.overrideWithValue(_happyClient())],
          child: _themed(const FeedScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Verified feed'), findsOneWidget);

      // Stats values
      expect(find.text('2,184'), findsOneWidget);
      expect(find.text('+28'), findsOneWidget);
      expect(find.text('SMS phishing'), findsOneWidget);

      // Stat labels
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('TOP TYPE'), findsOneWidget);

      // "All" filter + scam-type chips derived from reports
      expect(find.text('All'), findsOneWidget);
      // The chip labels appear twice each (once in chip bar, once in card chip)
      expect(find.text('Phishing SMS'), findsWidgets);
      expect(find.text('Phone impersonation'), findsWidgets);

      // Report titles
      expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
      expect(find.text('Caller pretending Revenue Department'), findsOneWidget);
    });

    testWidgets('shows error row when reports request fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [httpClientProvider.overrideWithValue(_errorClient())],
          child: _themed(const FeedScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load — tap to retry'), findsWidgets);
    });

    testWidgets('shows skeleton while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeStatsProvider.overrideWith(
              (ref) => Future<HomeStats>.delayed(const Duration(seconds: 30)),
            ),
            feedReportsProvider.overrideWith(
              (ref) => Future<List<RecentReport>>.delayed(
                  const Duration(seconds: 30)),
            ),
            httpClientProvider.overrideWithValue(
              MockClient((_) async => http.Response('{}', 200)),
            ),
          ],
          child: _themed(const FeedScreen()),
        ),
      );

      await tester.pump();

      // Real data not visible
      expect(find.text('2,184'), findsNothing);
      expect(find.text('Fake Kerry parcel SMS'), findsNothing);
    });

    testWidgets('tapping a filter chip narrows the report list',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [httpClientProvider.overrideWithValue(_happyClient())],
          child: _themed(const FeedScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Both reports visible initially
      expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
      expect(find.text('Caller pretending Revenue Department'), findsOneWidget);

      // Tap the "Phishing SMS" filter chip (first occurrence — the chip bar one)
      await tester.tap(find.text('Phishing SMS').first);
      await tester.pumpAndSettle();

      // Only phishing_sms report remains
      expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
      expect(find.text('Caller pretending Revenue Department'), findsNothing);

      // Tap "All" to reset
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Caller pretending Revenue Department'), findsOneWidget);
    });
  });
}
