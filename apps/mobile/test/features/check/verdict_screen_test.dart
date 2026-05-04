import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/check/domain/check_result.dart';
import 'package:mobile/features/check/presentation/check_providers.dart';
import 'package:mobile/features/check/presentation/verdict_screen.dart';
import 'package:mobile/l10n/l10n.dart';

const _query = CheckQuery(payload: '+66812345678', type: 'phone');

Widget _wrap(CheckQuery query, {required CheckResult result}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => VerdictScreen(query: query),
      ),
      GoRoute(
        path: '/feed',
        builder: (_, __) => const Scaffold(body: Text('feed')),
      ),
      GoRoute(
        path: '/submit-report',
        builder: (_, __) => const Scaffold(body: Text('submit-report')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      checkResultProvider(query).overrideWith((_) async => result),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('VerdictScreen', () {
    testWidgets('shows loading indicator + "Checking…" while pending',
        (tester) async {
      final completer = Completer<CheckResult>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkResultProvider(_query).overrideWith((_) => completer.future),
          ],
          child: MaterialApp(
            theme: lightTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const VerdictScreen(query: _query),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Checking…'), findsOneWidget);

      completer.complete(
        const CheckResult(verdict: 'safe', matchedCount: 0, matches: []),
      );
    });

    testWidgets('scam verdict renders "Scam" label + subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _query,
          result: const CheckResult(
            verdict: 'scam',
            matchedCount: 3,
            matches: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scam'), findsOneWidget);
      expect(
        find.text('Multiple verified reports match this item.'),
        findsOneWidget,
      );
    });

    testWidgets('safe verdict renders "Safe" + no "See matched reports"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          _query,
          result: const CheckResult(
            verdict: 'safe',
            matchedCount: 0,
            matches: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('See matched reports'), findsNothing);
    });

    testWidgets('"Report this" button always visible', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _query,
          result: const CheckResult(
            verdict: 'safe',
            matchedCount: 0,
            matches: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report this'), findsOneWidget);
    });

    testWidgets('cached result shows amber "Cached result" banner',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          _query,
          result: const CheckResult(
            verdict: 'scam',
            matchedCount: 1,
            matches: [],
            fromCache: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cached result'), findsOneWidget);
    });

    testWidgets('"See matched reports" visible when matchedCount > 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          _query,
          result: const CheckResult(
            verdict: 'scam',
            matchedCount: 2,
            matches: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('See matched reports'), findsOneWidget);
      expect(find.text('2 verified reports matched'), findsOneWidget);
    });
  });
}
