import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';
import 'package:mobile/features/moderation/presentation/mod_providers.dart';
import 'package:mobile/features/moderation/presentation/mod_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(Widget widget, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
}

ModQueueItem _item(String id, {bool flagged = false}) => ModQueueItem(
      id: id,
      title: 'Scam Report $id',
      scamTypeCode: 'PHISH',
      scamTypeLabelEn: 'Phishing',
      scamTypeLabelTh: 'ฟิชชิง',
      submittedAt: DateTime.utc(2026, 4, 20, 10),
      status: flagged ? 'flagged' : 'pending',
      priorityFlag: flagged,
      evidenceCount: 2,
      reporterHandle: '@testuser',
    );

ModQueueData _queue([int count = 2]) => ModQueueData(
      items: List.generate(count, (i) => _item('r${i + 1}')),
      pendingCount: count,
      flaggedCount: 0,
    );

void main() {
  group('ModScreen', () {
    testWidgets('shows skeleton rows while loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const ModScreen(),
        overrides: [
          modQueueProvider.overrideWith(
            (ref) => Future<ModQueueData>.delayed(const Duration(seconds: 30)),
          ),
          modFilteredQueueProvider.overrideWith(
            (ref) => const AsyncValue.loading(),
          ),
        ],
      ));

      await tester.pump();

      // 4 skeleton containers visible during loading.
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
        findsWidgets,
      );
    });

    testWidgets('renders queue item titles when data loads', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final queue = _queue(2);
      await tester.pumpWidget(_wrap(
        const ModScreen(),
        overrides: [
          modQueueProvider.overrideWith((ref) async => queue),
          modFilteredQueueProvider.overrideWith(
            (ref) => AsyncValue.data(queue.items),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Scam Report r1'), findsOneWidget);
      expect(find.text('Scam Report r2'), findsOneWidget);
    });

    testWidgets('shows empty-state text when filtered list is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const ModScreen(),
        overrides: [
          modQueueProvider.overrideWith(
            (ref) async => const ModQueueData(items: [], pendingCount: 0, flaggedCount: 0),
          ),
          modFilteredQueueProvider.overrideWith(
            (ref) => const AsyncValue.data([]),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Queue is empty'), findsOneWidget);
    });

    testWidgets('shows error text when modQueueProvider errors', (tester) async {
      await tester.pumpWidget(_wrap(
        const ModScreen(),
        overrides: [
          modQueueProvider.overrideWith(
            (ref) => Future<ModQueueData>.error(Exception('network error')),
          ),
          modFilteredQueueProvider.overrideWith(
            (ref) => AsyncValue.error(Exception('network error'), StackTrace.empty),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Exception'), findsOneWidget);
    });

    testWidgets('renders report items with type code chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final queue = _queue(1);
      await tester.pumpWidget(_wrap(
        const ModScreen(),
        overrides: [
          modQueueProvider.overrideWith((ref) async => queue),
          modFilteredQueueProvider.overrideWith(
            (ref) => AsyncValue.data(queue.items),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      // Type code chip renders in uppercase.
      expect(find.text('PHISH'), findsOneWidget);
      // Reporter handle visible.
      expect(find.text('@testuser'), findsOneWidget);
    });
  });
}
