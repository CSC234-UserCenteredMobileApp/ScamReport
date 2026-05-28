import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_persistence.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_state_codec.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_attachment.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/send_turn.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/submit_drafted_report.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

class _StubRepo implements AskAiRepository {
  TurnOutcome? next;

  @override
  Future<String> createConversation() async => 'c-1';

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ConversationSummary>> listConversations() async => const [];

  @override
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) async {
    return next!;
  }

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) async {
    return next!;
  }

  @override
  Future<void> upsertDraft(
      String conversationId, PersistedDraft? payload) async {}
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

ChatMessage _userMessage({
  String content = 'hi',
  List<ChatAttachment> attachments = const [],
}) =>
    ChatMessage(
      id: '11111111-1111-1111-1111-111111111111',
      role: ChatRole.user,
      content: content,
      intentDetected: false,
      createdAt: DateTime(2026, 5, 7),
      attachments: attachments,
    );

ChatMessage _assistantMessage() => ChatMessage(
      id: '22222222-2222-2222-2222-222222222222',
      role: ChatRole.assistant,
      content: 'reply',
      intentDetected: false,
      createdAt: DateTime(2026, 5, 7),
    );

class _NoopPersistence implements AskAiPersistence {
  @override
  Future<AskAiPersistedState?> load([String? userId]) async => null;
  @override
  Future<void> save(AskAiPersistedState state) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> clearForUser(String userId) async {}
}

Widget _wrap(_StubRepo repo) => ProviderScope(
      overrides: [
        askAiRepositoryProvider.overrideWithValue(repo),
        sendTurnUseCaseProvider.overrideWith((ref) => SendTurnUseCase(repo)),
        submitDraftedReportProvider.overrideWithValue(_StubSubmit()),
        askAiPersistenceProvider.overrideWithValue(_NoopPersistence()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AskAiScreen(),
      ),
    );

void main() {
  testWidgets(
      'image attachment with null signedUrl renders broken-image placeholder',
      (tester) async {
    final repo = _StubRepo()
      ..next = TurnOutcome(
        userMessage: _userMessage(
          attachments: const [
            ChatAttachment(
              id: 'a-1',
              mimeType: 'image/jpeg',
              sizeBytes: 1024,
              signedUrl: null,
            ),
          ],
        ),
        assistantMessage: _assistantMessage(),
        intentDetected: false,
        reportable: false,
        hasEnoughInfo: false,
        similarReports: const [],
      );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('askAiComposer')), 'with file');
    await tester.tap(find.byKey(const Key('askAiSendButton')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('pdf attachment renders pdf icon placeholder', (tester) async {
    final repo = _StubRepo()
      ..next = TurnOutcome(
        userMessage: _userMessage(
          attachments: const [
            ChatAttachment(
              id: 'a-1',
              mimeType: 'application/pdf',
              sizeBytes: 1024,
              signedUrl: 'https://example/x.pdf',
            ),
          ],
        ),
        assistantMessage: _assistantMessage(),
        intentDetected: false,
        reportable: false,
        hasEnoughInfo: false,
        similarReports: const [],
      );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('askAiComposer')), 'pdf send');
    await tester.tap(find.byKey(const Key('askAiSendButton')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('attachment-only message bubble renders without text',
      (tester) async {
    final repo = _StubRepo()
      ..next = TurnOutcome(
        userMessage: _userMessage(
          content: '',
          attachments: const [
            ChatAttachment(
              id: 'a-1',
              mimeType: 'image/jpeg',
              sizeBytes: 1,
              signedUrl: null,
            ),
          ],
        ),
        assistantMessage: _assistantMessage(),
        intentDetected: false,
        reportable: false,
        hasEnoughInfo: false,
        similarReports: const [],
      );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    // Send with empty content but no staged attachment → guarded.
    // Instead, simulate by setting state directly via provider override is
    // complex; this test exercises the bubble's render path via the
    // returned outcome.
    await tester.enterText(find.byKey(const Key('askAiComposer')), 'send');
    await tester.tap(find.byKey(const Key('askAiSendButton')));
    await tester.pumpAndSettle();
    // Bubble shows the broken-image placeholder for the attachment-only
    // user message returned by the stub.
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
