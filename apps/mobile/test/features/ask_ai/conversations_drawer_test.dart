import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/send_turn.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/submit_drafted_report.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';
import 'package:mobile/features/ask_ai/presentation/conversations_drawer.dart';
import 'package:mobile/l10n/app_localizations.dart';

class _StubRepo implements AskAiRepository {
  _StubRepo({this.list = const [], this.shouldThrowList = false});
  final List<ConversationSummary> list;
  final bool shouldThrowList;
  final List<String> deleted = [];

  @override
  Future<String> createConversation() async => 'c-1';

  @override
  Future<void> deleteConversation(String conversationId) async {
    deleted.add(conversationId);
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    return ConversationDetail(
      id: conversationId,
      createdAt: DateTime(2026, 5, 7),
      messages: const [],
    );
  }

  @override
  Future<List<ConversationSummary>> listConversations() async {
    if (shouldThrowList) throw Exception('boom');
    return list;
  }

  @override
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) {
    throw UnimplementedError();
  }
}

class _StubSubmit implements SubmitDraftedReport {
  @override
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
    List<EvidenceFileInput> evidenceFiles = const [],
  }) async {
    return (reportId: 'rep-1', createdAt: DateTime(2026, 5, 7));
  }
}

Widget _wrap(_StubRepo repo) {
  return ProviderScope(
    overrides: [
      askAiRepositoryProvider.overrideWithValue(repo),
      sendTurnUseCaseProvider.overrideWith((ref) => SendTurnUseCase(repo)),
      submitDraftedReportProvider.overrideWithValue(_StubSubmit()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        drawer: ConversationsDrawer(),
        body: Center(child: Text('home body')),
      ),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  final ScaffoldState scaffold = tester.firstState(find.byType(Scaffold));
  scaffold.openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders empty state when list is empty', (tester) async {
    await tester.pumpWidget(_wrap(_StubRepo()));
    await _openDrawer(tester);
    expect(find.text('No past chats yet. Send a message to start one.'),
        findsOneWidget);
    expect(find.byKey(const Key('askAiDrawerNewChat')), findsOneWidget);
  });

  testWidgets('renders conversation tiles when list is non-empty', (tester) async {
    await tester.pumpWidget(_wrap(_StubRepo(list: [
      ConversationSummary(
        id: 'c-1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
        preview: 'kerry parcel sms',
        linkedReportId: 'rep-1',
      ),
      ConversationSummary(
        id: 'c-2',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 5)),
        preview: '',
      ),
    ])));
    await _openDrawer(tester);
    expect(find.byKey(const Key('askAiConversationList')), findsOneWidget);
    expect(find.text('kerry parcel sms'), findsOneWidget);
    // Empty preview falls back to localised "(no preview)".
    expect(find.text('(no preview)'), findsOneWidget);
    // First tile has linkedReportId → flag icon.
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('renders error state when list throws', (tester) async {
    await tester.pumpWidget(_wrap(_StubRepo(shouldThrowList: true)));
    await _openDrawer(tester);
    expect(find.textContaining('Could not load conversations.'), findsOneWidget);
  });

  testWidgets('Refresh icon invalidates the provider', (tester) async {
    await tester.pumpWidget(_wrap(_StubRepo()));
    await _openDrawer(tester);
    await tester.tap(find.byKey(const Key('askAiDrawerRefresh')));
    await tester.pumpAndSettle();
    // No crash; widget still mounted.
    expect(find.byKey(const Key('askAiDrawerNewChat')), findsOneWidget);
  });

  testWidgets('New chat button resets controller and pops drawer', (tester) async {
    await tester.pumpWidget(_wrap(_StubRepo()));
    await _openDrawer(tester);
    await tester.tap(find.byKey(const Key('askAiDrawerNewChat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('askAiDrawerNewChat')), findsNothing);
  });

  testWidgets('Tap tile loads the conversation and closes drawer',
      (tester) async {
    final repo = _StubRepo(list: [
      ConversationSummary(
        id: 'c-1',
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        preview: 'first',
      ),
    ]);
    await tester.pumpWidget(_wrap(repo));
    await _openDrawer(tester);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('askAiDrawerNewChat')), findsNothing);
  });

  testWidgets('Long-press tile opens delete dialog and deletes on confirm',
      (tester) async {
    final repo = _StubRepo(list: [
      ConversationSummary(
        id: 'c-9',
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        preview: 'to delete',
      ),
    ]);
    await tester.pumpWidget(_wrap(repo));
    await _openDrawer(tester);
    await tester.longPress(find.text('to delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete conversation?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['c-9']);
  });
}
