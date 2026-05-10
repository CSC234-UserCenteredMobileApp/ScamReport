import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_persistence.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_state_codec.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/send_turn.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/submit_drafted_report.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';

class _StubRepo implements AskAiRepository {
  TurnOutcome? next;
  bool throwOnSend = false;
  Completer<TurnOutcome>? holdCompleter;

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
    if (throwOnSend) throw Exception('boom');
    if (holdCompleter != null) return holdCompleter!.future;
    return next ?? _basic(content);
  }

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) async {
    if (throwOnSend) throw Exception('boom');
    if (holdCompleter != null) return holdCompleter!.future;
    return next ?? _basic(content);
  }

  @override
  Future<void> upsertDraft(String conversationId, PersistedDraft? payload) async {}
}

class _StubSubmit implements SubmitDraftedReport {
  @override
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
    List<EvidenceFileInput> evidenceFiles = const [],
  }) async =>
      (reportId: 'rep-1', createdAt: DateTime(2026, 5, 7));
}

class _StubPersistence implements AskAiPersistence {
  AskAiPersistedState? loaded;
  int saveCalls = 0;
  int clearCalls = 0;
  @override
  Future<AskAiPersistedState?> load([String? userId]) async => loaded;
  @override
  Future<void> save(AskAiPersistedState state) async {
    saveCalls++;
  }
  @override
  Future<void> clear() async {
    clearCalls++;
  }
  @override
  Future<void> clearForUser(String userId) async {
    clearCalls++;
  }
}

TurnOutcome _basic(String content) => TurnOutcome(
      userMessage: ChatMessage(
        id: 'real-user',
        role: ChatRole.user,
        content: content,
        intentDetected: false,
        createdAt: DateTime(2026, 5, 7),
      ),
      assistantMessage: ChatMessage(
        id: 'real-assistant',
        role: ChatRole.assistant,
        content: 'reply',
        intentDetected: false,
        createdAt: DateTime(2026, 5, 7),
      ),
      intentDetected: false,
      reportable: false,
      hasEnoughInfo: false,
      similarReportIds: const [],
    );

ProviderContainer _container({
  required _StubRepo repo,
  AskAiPersistence? persistence,
}) {
  return ProviderContainer(overrides: [
    askAiRepositoryProvider.overrideWithValue(repo),
    sendTurnUseCaseProvider.overrideWith((ref) => SendTurnUseCase(repo)),
    submitDraftedReportProvider.overrideWithValue(_StubSubmit()),
    askAiPersistenceProvider
        .overrideWithValue(persistence ?? _StubPersistence()),
  ]);
}

void main() {
  test('optimistic user message appears immediately + clears staged', () async {
    final repo = _StubRepo()..holdCompleter = Completer();
    final container = _container(repo: repo);
    addTearDown(container.dispose);
    final notifier = container.read(askAiChatControllerProvider.notifier);
    notifier.stageAttachment(StagedAttachment(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
      filename: 'a.jpg',
    ));
    final future = notifier.sendMessage('hello');
    await Future<void>.delayed(Duration.zero);
    final mid = container.read(askAiChatControllerProvider);
    expect(mid.messages, hasLength(1));
    expect(mid.messages.first.id, startsWith('temp-'));
    expect(mid.messages.first.attachments.first.localBytes, isNotNull);
    expect(mid.stagedAttachments, isEmpty);
    expect(mid.isSending, isTrue);

    repo.holdCompleter!.complete(_basic('hello'));
    await future;

    final after = container.read(askAiChatControllerProvider);
    expect(after.isSending, isFalse);
    expect(after.messages.where((m) => m.id.startsWith('temp-')), isEmpty);
    expect(after.messages.map((m) => m.id),
        containsAll(['real-user', 'real-assistant']));
  });

  test('on send failure, optimistic bubble persists + lastFailedAttempt set',
      () async {
    final repo = _StubRepo()..throwOnSend = true;
    final container = _container(repo: repo);
    addTearDown(container.dispose);
    final notifier = container.read(askAiChatControllerProvider.notifier);
    notifier.stageAttachment(StagedAttachment(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
      filename: 'a.jpg',
    ));
    await notifier.sendMessage('hello');
    final state = container.read(askAiChatControllerProvider);
    expect(state.messages, hasLength(1));
    expect(state.messages.first.id, startsWith('temp-'));
    expect(state.error, isNotNull);
    expect(state.lastFailedAttempt, isNotNull);
    expect(state.lastFailedAttempt!.content, 'hello');
    expect(state.lastFailedAttempt!.attachments, hasLength(1));
  });

  test('retryLastFailedSend re-plays the same content + bytes', () async {
    final repo = _StubRepo()..throwOnSend = true;
    final container = _container(repo: repo);
    addTearDown(container.dispose);
    final notifier = container.read(askAiChatControllerProvider.notifier);
    notifier.stageAttachment(StagedAttachment(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
      filename: 'a.jpg',
    ));
    await notifier.sendMessage('hello');
    expect(container.read(askAiChatControllerProvider).error, isNotNull);

    repo.throwOnSend = false;
    repo.next = _basic('hello');
    await notifier.retryLastFailedSend();

    final state = container.read(askAiChatControllerProvider);
    expect(state.error, isNull);
    expect(state.messages.where((m) => m.id == 'real-user'), hasLength(1));
  });

  test('hydrate-on-construct restores cached composer state', () async {
    // iter-5: drafts now sync server-side; drift snapshot only carries
    // composer state (conversationId + stagedAttachments).
    final stub = _StubPersistence()
      ..loaded = AskAiPersistedState(
        conversationId: null,
        stagedAttachments: [
          StagedAttachment(
            bytes: Uint8List.fromList([9, 9]),
            mimeType: 'image/jpeg',
            filename: 'r.jpg',
          ),
        ],
      );
    final container =
        _container(repo: _StubRepo(), persistence: stub);
    addTearDown(container.dispose);
    // Force construction (Riverpod is lazy).
    container.read(askAiChatControllerProvider);
    // Allow the async _loadFromCache microtask to run.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = container.read(askAiChatControllerProvider);
    expect(state.stagedAttachments, hasLength(1));
  });
}
