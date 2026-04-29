import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/domain/home_stats.dart';
import 'package:mobile/features/home/domain/recent_alert.dart';
import 'package:mobile/features/home/domain/recent_report.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [widget] in the project theme + a fixed screen size so the
/// CustomScrollView has a deterministic viewport.
Widget _themed(Widget widget) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widget,
  );
}

/// A [MockClient] that responds with plausible home-screen data.
http.Client _happyClient() {
  return MockClient((request) async {
    if (request.url.path == '/stats') {
      return http.Response(
        jsonEncode({
          'data': {
            'verifiedTotal': 2184,
            'newThisWeek': 36,
            'topScamType': 'SMS phishing',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path == '/announcements') {
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'a1',
              'title': 'Surge in fake Songkran-themed parcel SMS scams',
              'category': 'fraud_alert',
              'publishedAt': '2026-04-23T00:00:00.000Z',
            },
            {
              'id': 'a2',
              'title': '5 quick ways to spot a phone-call scam',
              'category': 'tips',
              'publishedAt': '2026-04-19T00:00:00.000Z',
            },
          ],
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
              'title': 'Fake Grab promo phishing',
              'excerpt': 'A scammer posing as Grab sends a fake discount link.',
              'scamTypeCode': 'phishing_sms',
              'scamTypeLabelEn': 'Phishing SMS',
              'verifiedAt': '2026-04-20T00:00:00.000Z',
              'reportCount': 14,
            },
            {
              'id': 'r2',
              'title': 'QR code swap at ATM',
              'excerpt': 'Fraudsters stick a fake QR code over the real one.',
              'scamTypeCode': 'fake_qr',
              'scamTypeLabelEn': 'Fake QR',
              'verifiedAt': '2026-04-18T00:00:00.000Z',
              'reportCount': 7,
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

/// A [MockClient] that always returns 500.
http.Client _errorClient() {
  return MockClient((_) async => http.Response('server error', 500));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('HomeScreen', () {
    testWidgets('renders stat cards when data loads successfully',
        (tester) async {
      // Pin a screen size so the sliver list has a bounded viewport.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            httpClientProvider.overrideWithValue(_happyClient()),
          ],
          child: _themed(const HomeScreen()),
        ),
      );

      // Resolve all FutureProviders.
      await tester.pumpAndSettle();

      // Stats section — always in the viewport.
      // Numbers are comma-formatted (e.g. 2184 → "2,184").
      expect(find.text('2,184'), findsOneWidget);
      expect(find.text('+36'), findsOneWidget);
      expect(find.text('SMS phishing'), findsOneWidget);

      // Alert titles (visible without scrolling at this screen size).
      expect(
        find.text('Surge in fake Songkran-themed parcel SMS scams'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading skeleton before data arrives', (tester) async {
      // Override the FutureProviders directly so no timers are left pending.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeStatsProvider.overrideWith(
              (ref) => Future<HomeStats>.delayed(const Duration(seconds: 30)),
            ),
            recentAlertsProvider.overrideWith(
              (ref) =>
                  Future<List<RecentAlert>>.delayed(const Duration(seconds: 30)),
            ),
            recentReportsProvider.overrideWith(
              (ref) =>
                  Future<List<RecentReport>>.delayed(const Duration(seconds: 30)),
            ),
            httpClientProvider
                .overrideWithValue(MockClient((_) async => http.Response('{}', 200))),
          ],
          child: _themed(const HomeScreen()),
        ),
      );

      // One pump — providers are in loading state; skeleton boxes should be
      // rendered instead of real data.
      await tester.pump();

      // Real stat data must not be visible yet.
      expect(find.text('2,184'), findsNothing);
      expect(find.text('+36'), findsNothing);
    });

    testWidgets('shows error text when API returns 500', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            httpClientProvider.overrideWithValue(_errorClient()),
          ],
          child: _themed(const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // All three sections fail — at least one error message appears.
      expect(
        find.text('Failed to load — tap to retry'),
        findsWidgets,
      );
    });

    testWidgets('greeting is shown for guest user', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            httpClientProvider.overrideWithValue(_happyClient()),
          ],
          child: _themed(const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // currentUserProvider resolves null when there is no Firebase user →
      // the generic greeting "Hi 👋" is shown.
      expect(find.text('Hi 👋'), findsOneWidget);
      expect(find.text('Stay one step ahead of scams'), findsOneWidget);
    });
  });

  group('_ClipboardBanner dismiss', () {
    testWidgets('banner disappears when dismiss button is tapped',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Seed the clipboard provider so the banner renders immediately.
            clipboardValueProvider
                .overrideWith((ref) => '+66844192270'),
            httpClientProvider.overrideWithValue(_happyClient()),
          ],
          child: _themed(const HomeScreen()),
        ),
      );

      await tester.pump();

      // Banner text should be visible.
      expect(
        find.text('We noticed something on your clipboard'),
        findsOneWidget,
      );

      // Tap the dismiss (×) button.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Banner should be gone.
      expect(
        find.text('We noticed something on your clipboard'),
        findsNothing,
      );
    });
  });
}
