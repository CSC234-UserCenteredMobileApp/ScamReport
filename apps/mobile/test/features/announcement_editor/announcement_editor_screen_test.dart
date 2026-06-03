// Behavioral widget tests for the admin AnnouncementEditorScreen.
//
// Data dependencies: the screen reads `announcementEditorRepositoryProvider`
// directly (for mutations) and, in edit mode, watches
// `adminAnnouncementDetailProvider(id)` which itself flows through the
// repository's `getDetail`. So we override the repository with a mocktail mock
// and let the detail family resolve through it.
//
// The screen reads no auth/Firebase provider directly — overriding the
// repository means `announcementEditorApiProvider` (which builds the Firebase
// auth dependency) is never instantiated, so no auth override is needed.
//
// Mutations that end in `context.pop()` (update/publish/delete/unpublish) are
// avoided in tap tests; only the create-mode "Save Draft" branch mutates
// without popping, so the happy-path tap test lives in create mode.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/announcement_editor/domain/admin_announcement.dart';
import 'package:mobile/features/announcement_editor/domain/announcement_editor_repository.dart';
import 'package:mobile/features/announcement_editor/presentation/announcement_editor_providers.dart';
import 'package:mobile/features/announcement_editor/presentation/announcement_editor_screen.dart';
import 'package:mobile/l10n/l10n.dart';

class MockAnnouncementEditorRepository extends Mock
    implements AnnouncementEditorRepository {}

AdminAnnouncementDetail _detail({
  String id = 'ann-1',
  String title = 'Existing title',
  String body = 'Existing body',
  AdminAnnouncementStatus status = AdminAnnouncementStatus.draft,
  List<AnnouncementAttachment> attachments = const [],
}) {
  return AdminAnnouncementDetail(
    id: id,
    slug: 'existing-title',
    title: title,
    body: body,
    category: AdminAnnouncementCategory.fraudAlert,
    status: status,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 2),
    attachments: attachments,
    publishedAt: status == AdminAnnouncementStatus.published
        ? DateTime(2026, 5, 3)
        : null,
  );
}

Widget _wrap(
  Widget widget, {
  required AnnouncementEditorRepository repo,
}) {
  return ProviderScope(
    overrides: [
      announcementEditorRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
}

void main() {
  // Needed so `any(named: 'category')` can match the enum-typed argument.
  setUpAll(() => registerFallbackValue(AdminAnnouncementCategory.fraudAlert));

  late MockAnnouncementEditorRepository repo;

  setUp(() {
    repo = MockAnnouncementEditorRepository();
  });

  void pinViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('AnnouncementEditorScreen — edit mode', () {
    testWidgets('shows a loading spinner while the detail is fetching',
        (tester) async {
      pinViewport(tester);
      // Never-completing future → screen stays in the loading branch.
      final completer = Completer<AdminAnnouncementDetail>();
      when(() => repo.getDetail('ann-1')).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        _wrap(const AnnouncementEditorScreen(announcementId: 'ann-1'),
            repo: repo),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The form has not rendered yet.
      expect(
          find.widgetWithText(TextFormField, 'Existing title'), findsNothing);

      // Settle the pending future so teardown is clean.
      completer.complete(_detail());
      await tester.pumpAndSettle();
    });

    testWidgets('shows the error message when the detail fetch fails',
        (tester) async {
      pinViewport(tester);
      when(() => repo.getDetail('ann-1'))
          .thenThrow(Exception('boom while loading'));

      await tester.pumpWidget(
        _wrap(const AnnouncementEditorScreen(announcementId: 'ann-1'),
            repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('boom while loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('populates the form fields from the loaded draft detail',
        (tester) async {
      pinViewport(tester);
      when(() => repo.getDetail('ann-1')).thenAnswer((_) async => _detail());

      await tester.pumpWidget(
        _wrap(const AnnouncementEditorScreen(announcementId: 'ann-1'),
            repo: repo),
      );
      await tester.pumpAndSettle();

      // Edit-mode app bar.
      expect(find.text('Edit Announcement'), findsOneWidget);
      // Title + body controllers populated from the detail.
      expect(find.text('Existing title'), findsOneWidget);
      expect(find.text('Existing body'), findsOneWidget);
    });

    testWidgets('published announcement shows the unpublish banner + button',
        (tester) async {
      pinViewport(tester);
      when(() => repo.getDetail('ann-1')).thenAnswer(
        (_) async => _detail(status: AdminAnnouncementStatus.published),
      );

      await tester.pumpWidget(
        _wrap(const AnnouncementEditorScreen(announcementId: 'ann-1'),
            repo: repo),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unpublish to edit this announcement.'),
        findsOneWidget,
      );
      // Published state collapses the action bar to a single Unpublish button.
      expect(find.widgetWithText(FilledButton, 'Unpublish'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Save Draft'),
        findsNothing,
      );
    });
  });

  group('AnnouncementEditorScreen — create mode', () {
    testWidgets(
        'Save Draft with an empty title shows a validation error '
        'and does not call create', (tester) async {
      pinViewport(tester);

      await tester.pumpWidget(
        _wrap(const AnnouncementEditorScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Save Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      verifyNever(
        () => repo.create(
          title: any(named: 'title'),
          body: any(named: 'body'),
          category: any(named: 'category'),
        ),
      );
    });

    testWidgets('Save Draft with valid fields calls create on the repository',
        (tester) async {
      pinViewport(tester);
      when(
        () => repo.create(
          title: 'My alert',
          body: 'Watch out for this scam',
          category: AdminAnnouncementCategory.fraudAlert,
        ),
      ).thenAnswer((_) async => _detail(id: 'new-id', title: 'My alert'));
      // After create sets _savedId, the screen flips to edit mode and watches
      // the detail provider → stub getDetail so pumpAndSettle resolves cleanly.
      when(() => repo.getDetail('new-id')).thenAnswer(
        (_) async => _detail(id: 'new-id', title: 'My alert'),
      );

      await tester.pumpWidget(
        _wrap(const AnnouncementEditorScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'My alert',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Body'),
        'Watch out for this scam',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Save Draft'));
      await tester.pumpAndSettle();

      verify(
        () => repo.create(
          title: 'My alert',
          body: 'Watch out for this scam',
          category: AdminAnnouncementCategory.fraudAlert,
        ),
      ).called(1);
    });
  });
}
