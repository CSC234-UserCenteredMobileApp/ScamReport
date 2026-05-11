import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/send_turn.dart';

class _FakeRepo implements AskAiRepository {
  _FakeRepo();
  final String createConvId = 'new-convo-id';
  int createCalls = 0;
  String? sendConversationId;
  String? sendContent;

  @override
  Future<String> createConversation() async {
    createCalls++;
    return createConvId;
  }

  @override
  Future<List<ConversationSummary>> listConversations() async => const [];

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    return ConversationDetail(
      id: conversationId,
      createdAt: DateTime(2026, 5, 7),
      messages: const [],
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> upsertDraft(String conversationId, PersistedDraft? payload) async {}

  @override
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) async {
    sendConversationId = conversationId;
    sendContent = content;
    final ts = DateTime(2026, 5, 7);
    return TurnOutcome(
      userMessage: ChatMessage(
        id: 'u',
        role: ChatRole.user,
        content: content,
        intentDetected: false,
        createdAt: ts,
      ),
      assistantMessage: ChatMessage(
        id: 'a',
        role: ChatRole.assistant,
        content: 'Hello!',
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

void main() {
  group('SendTurnUseCase', () {
    test('lazily creates a conversation when no id is given', () async {
      final repo = _FakeRepo();
      final useCase = SendTurnUseCase(repo);

      final result = await useCase(content: 'hi');

      expect(repo.createCalls, 1);
      expect(result.conversationId, 'new-convo-id');
      expect(repo.sendConversationId, 'new-convo-id');
      expect(repo.sendContent, 'hi');
    });

    test('reuses an existing conversation id without creating a new one', () async {
      final repo = _FakeRepo();
      final useCase = SendTurnUseCase(repo);

      await useCase(conversationId: 'existing', content: 'second message');

      expect(repo.createCalls, 0);
      expect(repo.sendConversationId, 'existing');
    });

    test('rejects empty content', () async {
      final repo = _FakeRepo();
      final useCase = SendTurnUseCase(repo);
      await expectLater(
        () => useCase(content: '   '),
        throwsArgumentError,
      );
    });

    test('returns the outcome from the repository', () async {
      final repo = _FakeRepo();
      final useCase = SendTurnUseCase(repo);
      final result = await useCase(content: 'hi');
      expect(result.outcome.assistantMessage.content, 'Hello!');
      expect(result.outcome.reportable, isFalse);
      expect(result.outcome.draft, isNull);
    });
  });
}
