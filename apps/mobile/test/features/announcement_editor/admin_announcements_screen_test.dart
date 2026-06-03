// Behavior of the admin "Manage Announcements" list screen:
//  - loading spinner while the repository is still fetching
//  - loaded list renders one tile per announcement
//  - empty result shows the "No announcements" placeholder
//  - a repository error surfaces the error message
//  - tapping a status filter chip narrows the list (real provider chain)
//  - the "+" FAB navigates to the new-announcement route
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/announcement_editor/domain/admin_announcement.dart';
import 'package:mobile/features/announcement_editor/domain/announcement_editor_repository.dart';
import 'package:mobile/features/announcement_editor/presentation/admin_announcements_screen.dart';
import 'package:mobile/features/announcement_editor/presentation/announcement_editor_providers.dart';
import 'package:mobile/l10n/l10n.dart';

class _MockRepo extends Mock implements AnnouncementEditorRepository {}

AdminAnnouncementListItem _item({
  required String id,
  required String title,
  required AdminAnnouncementStatus status,
  AdminAnnouncementCategory category = AdminAnnouncementCategory.fraudAlert,
}) {
  return AdminAnnouncementListItem(
    id: id,
    slug: 'slug-$id',
    title: title,
    category: category,
    status: status,
    createdAt: DateTime(2026, 5, 1),
  );
}

/// Wraps [screen] in a GoRouter so `context.push(...)` calls resolve to stub
/// destination routes instead of throwing.
Widget _wrap(Widget screen, {required List<Override> overrides}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      GoRoute(
        path: '/admin/announcements/new',
        builder: (_, __) => const Scaffold(body: Text('new-screen')),
      ),
      GoRoute(
        path: '/admin/announcements/:id/edit',
        builder: (_, __) => const Scaffold(body: Text('edit-screen')),
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

void _pinViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  List<Override> overrides() => [
        announcementEditorRepositoryProvider.overrideWithValue(repo),
      ];

  testWidgets('shows a spinner while the list is loading', (tester) async {
    _pinViewport(tester);
    // Never-completing future keeps the provider in the loading state.
    when(() => repo.listAll())
        .thenAnswer((_) => Completer<List<AdminAnnouncementListItem>>().future);

    await tester.pumpWidget(
      _wrap(const AdminAnnouncementsScreen(), overrides: overrides()),
    );
    // Single pump only — pumpAndSettle would time out on the spinner animation.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No announcements'), findsNothing);
  });

  testWidgets('renders a tile per announcement when data loads',
      (tester) async {
    _pinViewport(tester);
    when(() => repo.listAll()).thenAnswer(
      (_) async => [
        _item(
          id: '1',
          title: 'Fake parcel SMS surge',
          status: AdminAnnouncementStatus.published,
        ),
        _item(
          id: '2',
          title: 'Phone-call scam tips',
          status: AdminAnnouncementStatus.draft,
          category: AdminAnnouncementCategory.tips,
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(const AdminAnnouncementsScreen(), overrides: overrides()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fake parcel SMS surge'), findsOneWidget);
    expect(find.text('Phone-call scam tips'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the empty placeholder when there are no announcements',
      (tester) async {
    _pinViewport(tester);
    when(() => repo.listAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      _wrap(const AdminAnnouncementsScreen(), overrides: overrides()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No announcements'), findsOneWidget);
  });

  testWidgets('surfaces the error message when the repository throws',
      (tester) async {
    _pinViewport(tester);
    when(() => repo.listAll()).thenAnswer((_) async => throw Exception('boom'));

    await tester.pumpWidget(
      _wrap(const AdminAnnouncementsScreen(), overrides: overrides()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('tapping the "Draft" filter chip narrows the list to drafts',
      (tester) async {
    _pinViewport(tester);
    when(() => repo.listAll()).thenAnswer(
      (_) async => [
        _item(
          id: '1',
          title: 'Published item alpha',
          status: AdminAnnouncementStatus.published,
        ),
        _item(
          id: '2',
          title: 'Draft item beta',
          status: AdminAnnouncementStatus.draft,
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(const AdminAnnouncementsScreen(), overrides: overrides()),
    );
    await tester.pumpAndSettle();

    // Both visible under the default "All" filter.
    expect(find.text('Published item alpha'), findsOneWidget);
    expect(find.text('Draft item beta'), findsOneWidget);

    // Tap the "Draft" filter chip (capitalized label on the FilterChip).
    await tester.tap(find.widgetWithText(FilterChip, 'Draft'));
    await tester.pumpAndSettle();

    // Only the draft tile remains.
    expect(find.text('Draft item beta'), findsOneWidget);
    expect(find.text('Published item alpha'), findsNothing);
  });

  testWidgets('the "+" FAB navigates to the new-announcement route',
      (tester) async {
    _pinViewport(tester);
    when(() => repo.listAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      _wrap(const AdminAnnouncementsScreen(), overrides: overrides()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('new-screen'), findsOneWidget);
  });
}
