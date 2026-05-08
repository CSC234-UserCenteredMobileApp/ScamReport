import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/send_turn.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/submit_drafted_report.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

class _StubRepo implements AskAiRepository {
  TurnOutcome? _next;
  final List<String> sent = [];

  void respondWith(TurnOutcome outcome) => _next = outcome;

  @override
  Future<String> createConversation() async => 'conv-1';

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ConversationSummary>> listConversations() async => const [];

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) async {
    sent.add(content);
    final ts = DateTime(2026, 5, 7);
    return _next ??
        TurnOutcome(
          userMessage: ChatMessage(
            id: 'u-${sent.length}',
            role: ChatRole.user,
            content: content,
            intentDetected: false,
            createdAt: ts,
          ),
          assistantMessage: ChatMessage(
            id: 'a-${sent.length}',
            role: ChatRole.assistant,
            content: 'AI reply ${sent.length}',
            intentDetected: false,
            createdAt: ts,
          ),
          intentDetected: false,
          reportable: false,
          hasEnoughInfo: false,
          similarReportIds: const [],
        );
  }
}

class _StubSubmit implements SubmitDraftedReport {
  final List<String> calls = [];
  @override
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
  }) async {
    calls.add(sourceConversationId);
    return (
      reportId: 'rep-${calls.length}',
      createdAt: DateTime(2026, 5, 7),
    );
  }
}

Widget _wrap(_StubRepo repo, {_StubSubmit? submit}) {
  final stubSubmit = submit ?? _StubSubmit();
  return ProviderScope(
    overrides: [
      askAiRepositoryProvider.overrideWithValue(repo),
      sendTurnUseCaseProvider.overrideWith((ref) => SendTurnUseCase(repo)),
      submitDraftedReportProvider.overrideWithValue(stubSubmit),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AskAiScreen(),
    ),
  );
}

void main() {
  testWidgets('renders empty state with welcome bubble + BETA badge', (tester) async {
    await tester.pumpWidget(_wrap(_StubRepo()));
    await tester.pumpAndSettle();

    // Default locale resolves to en — strings come from app_en.arb.
    expect(find.text('Ask ScamReport'), findsOneWidget);
    expect(find.text('BETA'), findsOneWidget);
    expect(find.text('Hi, I\'m your scam radar.'), findsOneWidget);
  });

  testWidgets('sending a message renders user bubble + assistant bubble', (tester) async {
    final repo = _StubRepo();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('askAiComposer')), 'I got a weird SMS');
    await tester.tap(find.byKey(const Key('askAiSendButton')));
    await tester.pumpAndSettle();

    expect(repo.sent, ['I got a weird SMS']);
    expect(find.text('I got a weird SMS'), findsOneWidget);
    expect(find.text('AI reply 1'), findsOneWidget);
  });

  testWidgets('does not send when composer is empty', (tester) async {
    final repo = _StubRepo();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('askAiSendButton')));
    await tester.pumpAndSettle();

    expect(repo.sent, isEmpty);
  });
}
