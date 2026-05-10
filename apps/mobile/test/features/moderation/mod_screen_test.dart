import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';
import 'package:mobile/features/moderation/presentation/mod_providers.dart';
import 'package:mobile/features/moderation/presentation/mod_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(
  Widget widget, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: widget,
    ),
  );
}

ModQueueItem _item(String id, {bool flagged = false, String? lastRemark}) =>
    ModQueueItem(
      id: id,
      title: 'Scam Report $id',
      scamTypeCode: 'phishing_sms',
      scamTypeLabelEn: 'Phishing SMS',
      scamTypeLabelTh: 'ฟิชชิง SMS',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: flagged ? 'flagged' : 'pending',
      priorityFlag: flagged,
      evidenceCount: 2,
      lastRemarkByAdmin: lastRemark,
    );

ModQueueData _queue([int count = 2]) => ModQueueData(
      items: List.generate(count, (i) => _item('r${i + 1}')),
      pendingCount: count,
      flaggedCount: 0,
    );

void main() {
  setUpAll(() {
    // Larger surface keeps the IntrinsicHeight queue rows from overflowing
    // the test viewport.
  });

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

      // Skeleton placeholder boxes render during loading.
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

    testWidgets('renders English scam-type label by default', (tester) async {
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

      expect(find.text('Phishing SMS'), findsOneWidget);
    });

    testWidgets('renders Thai scam-type label when locale is th',
        (tester) async {
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
        locale: const Locale('th'),
      ));

      await tester.pumpAndSettle();

      expect(find.text('ฟิชชิง SMS'), findsOneWidget);
    });

    testWidgets(
      'never renders reporter identity (FR-7.4 anti-regression)',
      (tester) async {
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

        expect(find.textContaining('User_'), findsNothing);
        expect(find.textContaining('@user'), findsNothing);
        expect(find.textContaining('@testuser'), findsNothing);
      },
    );

    testWidgets('shows empty-state text when filtered list is empty',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const ModScreen(),
        overrides: [
          modQueueProvider.overrideWith(
            (ref) async => const ModQueueData(
              items: [],
              pendingCount: 0,
              flaggedCount: 0,
            ),
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

    testWidgets('flagged variant renders team note', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final flagged = _item('r1', flagged: true, lastRemark: 'Need consensus');
      final queue = ModQueueData(
        items: [flagged],
        pendingCount: 0,
        flaggedCount: 1,
      );
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

      expect(find.textContaining('Need consensus'), findsOneWidget);
    });
  });
}
