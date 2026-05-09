import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/search/presentation/search_providers.dart';
import 'package:mobile/features/search/presentation/search_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _themed(Widget widget, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: widget,
    ),
  );
}

http.Client _reportsClient({
  List<Map<String, dynamic>> items = const [],
  int statusCode = 200,
}) {
  return MockClient((request) async {
    if (request.url.path == '/reports') {
      if (statusCode >= 400) {
        return http.Response('server error', statusCode);
      }
      return http.Response(
        jsonEncode({'items': items}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path == '/scam-types') {
      return http.Response(
        jsonEncode({'items': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('not found', 404);
  });
}

const _twoItems = [
  {
    'id': '00000000-0000-0000-0000-000000000001',
    'title': 'Phone scam alert',
    'excerpt': 'Caller asked for OTP.',
    'scamTypeCode': 'phone',
    'scamTypeLabelEn': 'Phone Scam',
    'scamTypeLabelTh': 'หลอกลวงทางโทรศัพท์',
    'verifiedAt': '2026-05-01T00:00:00.000Z',
    'reportCount': 3,
  },
  {
    'id': '00000000-0000-0000-0000-000000000002',
    'title': 'Phishing link',
    'excerpt': 'Fake bank login page.',
    'scamTypeCode': 'phishing',
    'scamTypeLabelEn': 'Phishing',
    'scamTypeLabelTh': 'ฟิชชิ่ง',
    'verifiedAt': '2026-04-30T00:00:00.000Z',
    'reportCount': 1,
  },
];

void main() {
  group('SearchScreen', () {
    testWidgets('renders title and search input', (tester) async {
      await tester.pumpWidget(_themed(const SearchScreen()));
      await tester.pump();

      expect(find.text('Search'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows filter chip below search bar', (tester) async {
      await tester.pumpWidget(_themed(const SearchScreen()));
      await tester.pump();

      expect(find.text('Filter & Sort'), findsOneWidget);
    });

    testWidgets('shows empty prompt on initial load with no query', (tester) async {
      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider.overrideWithValue(_reportsClient()),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Type something to search verified reports.'), findsOneWidget);
    });

    testWidgets('shows results after typing a query', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider
              .overrideWithValue(_reportsClient(items: _twoItems)),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pumpAndSettle();

      expect(find.text('Phone scam alert'), findsOneWidget);
      expect(find.text('Phishing link'), findsOneWidget);
    });

    testWidgets('shows no-results message when API returns empty list',
        (tester) async {
      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider.overrideWithValue(_reportsClient()),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nothing');
      await tester.pumpAndSettle();

      expect(find.text('No reports matched your search.'), findsOneWidget);
    });

    testWidgets('shows error state with retry button on API failure',
        (tester) async {
      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider
              .overrideWithValue(_reportsClient(statusCode: 500)),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pumpAndSettle();

      expect(find.text('Failed to load — tap to retry'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('clear button appears when text is entered', (tester) async {
      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider.overrideWithValue(_reportsClient()),
        ],
      ));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('clear button clears the text field', (tester) async {
      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider.overrideWithValue(_reportsClient()),
        ],
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text, '');
    });

    testWidgets('filter badge shows when sort is changed', (tester) async {
      await tester.pumpWidget(_themed(
        const SearchScreen(),
        overrides: [
          httpClientProvider.overrideWithValue(_reportsClient()),
          searchSortByProvider.overrideWith((ref) => 'reportCount'),
        ],
      ));
      await tester.pump();

      expect(find.byType(Badge), findsOneWidget);
    });
  });
}
