// Notifications inbox screen behavior:
//  - loading spinner while the inbox future is pending
//  - loaded list renders tiles + "Mark all as read" when there are unread items
//  - empty state copy when the inbox has no items
//  - error copy when the inbox future throws
//  - tapping a tile with a reportId navigates to the report-detail route
//  - "Mark all as read" calls markRead with the unread ids
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';
import 'package:mobile/features/notifications/domain/notifications_repository.dart';
import 'package:mobile/features/notifications/presentation/notification_tile.dart';
import 'package:mobile/features/notifications/presentation/notifications_inbox_screen.dart';
import 'package:mobile/features/notifications/presentation/notifications_providers.dart';
import 'package:mobile/l10n/l10n.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

AppNotification _notif({
  required String id,
  String title = 'Report verified',
  String body = 'Your report was approved.',
  String? reportId,
  bool isRead = false,
  NotificationKind kind = NotificationKind.reportVerified,
}) {
  return AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    reportId: reportId,
    isRead: isRead,
    // Fixed in the past so the age label is deterministic ("Xh ago").
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

NotificationListData _data({
  required List<AppNotification> items,
  required int unreadCount,
}) {
  return NotificationListData(items: items, unreadCount: unreadCount);
}

/// Wraps the screen in a GoRouter with a stub report-detail destination so
/// `context.push('/report-detail/<id>')` has somewhere to land.
Widget _wrap(Widget widget, {required List<Override> overrides}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => widget),
      GoRoute(
        path: '/report-detail/:id',
        builder: (context, state) => Scaffold(
          body: Text('detail ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  late MockNotificationsRepository repo;

  setUp(() {
    repo = MockNotificationsRepository();
    when(() => repo.markRead(any())).thenAnswer((_) async => 1);
  });

  void pinViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('NotificationsInboxScreen', () {
    testWidgets('shows a spinner while the inbox future is loading',
        (tester) async {
      pinViewport(tester);
      // A future that never completes keeps the provider in the loading state
      // without leaving a pending timer at teardown.
      final pending = Completer<NotificationListData>();
      addTearDown(() => pending.complete(_data(items: [], unreadCount: 0)));

      await tester.pumpWidget(
        _wrap(
          const NotificationsInboxScreen(),
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            notificationsInboxProvider.overrideWith((ref) => pending.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('You have no notifications yet.'), findsNothing);
    });

    testWidgets('renders notification tiles and the mark-all action',
        (tester) async {
      pinViewport(tester);
      await tester.pumpWidget(
        _wrap(
          const NotificationsInboxScreen(),
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            notificationsInboxProvider.overrideWith(
              (ref) async => _data(
                items: [
                  _notif(
                    id: 'n1',
                    title: 'Report verified',
                    reportId: 'r1',
                    isRead: false,
                  ),
                  _notif(
                    id: 'n2',
                    title: 'Report flagged',
                    kind: NotificationKind.reportFlagged,
                    isRead: true,
                  ),
                ],
                unreadCount: 1,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsNWidgets(2));
      expect(find.text('Report verified'), findsOneWidget);
      expect(find.text('Report flagged'), findsOneWidget);
      // The mark-all action only appears when there are unread items.
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    testWidgets('shows the empty-state copy when there are no notifications',
        (tester) async {
      pinViewport(tester);
      await tester.pumpWidget(
        _wrap(
          const NotificationsInboxScreen(),
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            notificationsInboxProvider.overrideWith(
              (ref) async => _data(items: [], unreadCount: 0),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You have no notifications yet.'), findsOneWidget);
      expect(find.byType(NotificationTile), findsNothing);
      // No unread items => no mark-all action.
      expect(find.text('Mark all as read'), findsNothing);
    });

    testWidgets('shows the error copy when the inbox future throws',
        (tester) async {
      pinViewport(tester);
      await tester.pumpWidget(
        _wrap(
          const NotificationsInboxScreen(),
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            notificationsInboxProvider.overrideWith(
              (ref) async => throw Exception('boom'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load notifications.'), findsOneWidget);
    });

    testWidgets('tapping a tile with a reportId navigates to report detail',
        (tester) async {
      pinViewport(tester);
      await tester.pumpWidget(
        _wrap(
          const NotificationsInboxScreen(),
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            notificationsInboxProvider.overrideWith(
              (ref) async => _data(
                items: [
                  _notif(id: 'n1', reportId: 'r-42', isRead: false),
                ],
                unreadCount: 1,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationTile));
      await tester.pumpAndSettle();

      // Landed on the stub destination for report r-42.
      expect(find.text('detail r-42'), findsOneWidget);
      // Tapping an unread tile marks it read first.
      verify(() => repo.markRead(['n1'])).called(1);
    });

    testWidgets('"Mark all as read" calls markRead with the unread ids',
        (tester) async {
      pinViewport(tester);
      await tester.pumpWidget(
        _wrap(
          const NotificationsInboxScreen(),
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            notificationsInboxProvider.overrideWith(
              (ref) async => _data(
                items: [
                  _notif(id: 'n1', isRead: false),
                  _notif(id: 'n2', isRead: true),
                  _notif(id: 'n3', isRead: false),
                ],
                unreadCount: 2,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      // Only the unread ids are sent, in list order.
      verify(() => repo.markRead(['n1', 'n3'])).called(1);
    });
  });
}
