import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/alerts/domain/alert.dart';
import 'package:mobile/features/alerts/presentation/alerts_providers.dart';
import 'package:mobile/features/alerts/presentation/announcement_detail_screen.dart';
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

void main() {
  group('AnnouncementDetailScreen', () {
    const fakeId = 'test-id-123';

    Alert _fakeAlert() => Alert(
          id: fakeId,
          title: 'New Scam Wave',
          excerpt: 'Scammers use SMS to lure victims.',
          body: 'Full body text.\n• Bullet point one\n• Bullet point two',
          category: AlertCategory.fraudAlert,
          publishedAt: DateTime.utc(2026, 4, 23),
          slug: 'new-scam-wave',
        );

    testWidgets('shows loading indicator before data arrives', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Slow mock keeps the provider in AsyncLoading for the test.
            httpClientProvider.overrideWithValue(
              MockClient(
                (_) => Completer<http.Response>().future,
              ),
            ),
          ],
          child: _themed(const AnnouncementDetailScreen(id: fakeId)),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders title and body when data loads', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertDetailProvider(fakeId)
                .overrideWith((ref) async => _fakeAlert()),
          ],
          child: _themed(const AnnouncementDetailScreen(id: fakeId)),
        ),
      );

      await tester.pumpAndSettle();

      // Title appears in AppBar and in the body headline.
      expect(find.text('New Scam Wave'), findsWidgets);
      expect(find.text('Full body text.'), findsOneWidget);
    });

    testWidgets('renders bullet point lines from body', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertDetailProvider(fakeId)
                .overrideWith((ref) async => _fakeAlert()),
          ],
          child: _themed(const AnnouncementDetailScreen(id: fakeId)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bullet point one'), findsOneWidget);
      expect(find.text('Bullet point two'), findsOneWidget);
    });

    testWidgets('share button is present in the app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertDetailProvider(fakeId)
                .overrideWith((ref) async => _fakeAlert()),
          ],
          child: _themed(const AnnouncementDetailScreen(id: fakeId)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('shows error state when fetch fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertDetailProvider(fakeId).overrideWith(
              (ref) => Future<Alert>.error(Exception('network error')),
            ),
          ],
          child: _themed(const AnnouncementDetailScreen(id: fakeId)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load — tap to retry'), findsOneWidget);
    });
  });
}
