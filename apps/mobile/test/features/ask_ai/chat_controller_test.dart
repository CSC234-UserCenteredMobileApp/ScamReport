import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_persistence.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_state_codec.dart';
import 'package:mobile/features/ask_ai/domain/ask_ai_repository.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/domain/entities/chat_message.dart';
import 'package:mobile/features/ask_ai/domain/entities/conversation.dart';
import 'package:mobile/features/ask_ai/domain/entities/turn_outcome.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/send_turn.dart';
import 'package:mobile/features/ask_ai/domain/use_cases/submit_drafted_report.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';
import 'dart:typed_data';

class _StubRepo implements AskAiRepository {
  TurnOutcome? next;
  bool throwOnSend = false;
  String? loadedId;

  @override
  Future<String> createConversation() async => 'c-1';

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    loadedId = conversationId;
    return ConversationDetail(
      id: conversationId,
      createdAt: DateTime(2026, 5, 7),
      messages: [
        ChatMessage(
          id: 'm-old',
          role: ChatRole.user,
          content: 'old',
          intentDetected: false,
          createdAt: DateTime(2026, 5, 7),
        ),
      ],
      linkedReportId: 'rep-old',
    );
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
    return next ?? _basicOutcome(content);
  }

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) async {
    return next ?? _basicOutcome(content);
  }

  final List<({String conversationId, PersistedDraft? payload})> draftUpserts = [];

  @override
  Future<void> upsertDraft(String conversationId, PersistedDraft? payload) async {
    draftUpserts.add((conversationId: conversationId, payload: payload));
  }
}

class _StubSubmit implements SubmitDraftedReport {
  bool throws = false;
  String? capturedConversationId;
  AiDraft? capturedDraft;
  @override
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
    List<EvidenceFileInput> evidenceFiles = const [],
  }) async {
    if (throws) throw Exception('submit failed');
    capturedConversationId = sourceConversationId;
    capturedDraft = draft;
    return (reportId: 'rep-1', createdAt: DateTime(2026, 5, 7));
  }
}

TurnOutcome _basicOutcome(String content) => TurnOutcome(
      userMessage: ChatMessage(
        id: 'u',
        role: ChatRole.user,
        content: content,
        intentDetected: false,
        createdAt: DateTime(2026, 5, 7),
      ),
      assistantMessage: ChatMessage(
        id: 'a',
        role: ChatRole.assistant,
        content: 'reply',
        intentDetected: false,
        createdAt: DateTime(2026, 5, 7),
      ),
      intentDetected: false,
      reportable: false,
      hasEnoughInfo: false,
      similarReports: const [],
    );

class _StubPersistence implements AskAiPersistence {
  final saved = <AskAiPersistedState>[];
  int clearCalls = 0;
  AskAiPersistedState? loaded;
  @override
  Future<AskAiPersistedState?> load([String? userId]) async => loaded;
  @override
  Future<void> save(AskAiPersistedState state) async {
    saved.add(state);
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

ProviderContainer _container(
  _StubRepo repo,
  _StubSubmit submit, {
  AskAiPersistence? persistence,
}) {
  return ProviderContainer(overrides: [
    askAiRepositoryProvider.overrideWithValue(repo),
    sendTurnUseCaseProvider.overrideWith((ref) => SendTurnUseCase(repo)),
    submitDraftedReportProvider.overrideWithValue(submit),
    askAiPersistenceProvider
        .overrideWithValue(persistence ?? _StubPersistence()),
  ]);
}

void main() {
  group('AskAiChatController', () {
    test('sendMessage stages user + assistant messages', () async {
      final repo = _StubRepo();
      final container = _container(repo, _StubSubmit());
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .sendMessage('hi');
      final state = container.read(askAiChatControllerProvider);
      expect(state.messages, hasLength(2));
      expect(state.conversationId, 'c-1');
      expect(state.error, isNull);
    });

    test('empty content is ignored', () async {
      final repo = _StubRepo();
      final container = _container(repo, _StubSubmit());
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .sendMessage('   ');
      expect(container.read(askAiChatControllerProvider).messages, isEmpty);
    });

    test('error path captures error and clears isSending', () async {
      final repo = _StubRepo()..throwOnSend = true;
      final container = _container(repo, _StubSubmit());
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .sendMessage('boom');
      final state = container.read(askAiChatControllerProvider);
      expect(state.isSending, isFalse);
      expect(state.error, isNotNull);
    });

    test('reportable outcome populates activeDraft', () async {
      final repo = _StubRepo()
        ..next = TurnOutcome(
          userMessage: _basicOutcome('hi').userMessage,
          assistantMessage: _basicOutcome('hi').assistantMessage,
          intentDetected: true,
          reportable: true,
          hasEnoughInfo: true,
          similarReports: const [],
          draft: const AiDraft(
            title: 'A drafted title here',
            description: 'A drafted description here that is long.',
            scamTypeCode: 'phishing_sms',
          ),
        );
      final container = _container(repo, _StubSubmit());
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .sendMessage('I clicked a phishing link');
      final state = container.read(askAiChatControllerProvider);
      expect(state.activeDraft, isNotNull);
      expect(state.canOfferReport, isTrue);
    });

    test('updateDraft replaces activeDraft', () async {
      final repo = _StubRepo();
      final container = _container(repo, _StubSubmit());
      addTearDown(container.dispose);
      const replacement = AiDraft(
        title: 'Replacement title here',
        description: 'Replacement description here that is long.',
        scamTypeCode: 'other',
      );
      container
          .read(askAiChatControllerProvider.notifier)
          .updateDraft(replacement);
      expect(
        container.read(askAiChatControllerProvider).activeDraft,
        replacement,
      );
    });

    test('submitActiveDraft posts draft and stores report id', () async {
      final repo = _StubRepo();
      final submit = _StubSubmit();
      final container = _container(repo, submit);
      addTearDown(container.dispose);
      // Seed conversation + draft.
      await container
          .read(askAiChatControllerProvider.notifier)
          .sendMessage('hi');
      container
          .read(askAiChatControllerProvider.notifier)
          .updateDraft(const AiDraft(
            title: 'A drafted title here',
            description: 'A drafted description here that is long.',
            scamTypeCode: 'phishing_sms',
          ));
      await container
          .read(askAiChatControllerProvider.notifier)
          .submitActiveDraft();
      final state = container.read(askAiChatControllerProvider);
      expect(state.submittedReportId, 'rep-1');
      expect(submit.capturedConversationId, 'c-1');
    });

    test('submitActiveDraft no-op when no draft', () async {
      final container = _container(_StubRepo(), _StubSubmit());
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .submitActiveDraft();
      expect(
        container.read(askAiChatControllerProvider).submittedReportId,
        isNull,
      );
    });

    test('submit error is captured', () async {
      final repo = _StubRepo();
      final submit = _StubSubmit()..throws = true;
      final container = _container(repo, submit);
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .sendMessage('hi');
      container
          .read(askAiChatControllerProvider.notifier)
          .updateDraft(const AiDraft(
            title: 'A drafted title here',
            description: 'A drafted description here that is long.',
            scamTypeCode: 'phishing_sms',
          ));
      await container
          .read(askAiChatControllerProvider.notifier)
          .submitActiveDraft();
      final state = container.read(askAiChatControllerProvider);
      expect(state.error, isNotNull);
      expect(state.submittedReportId, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('stage + remove attachments', () async {
      final container = _container(_StubRepo(), _StubSubmit());
      addTearDown(container.dispose);
      final notifier = container.read(askAiChatControllerProvider.notifier);
      notifier.stageAttachment(StagedAttachment(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
        filename: 'a.jpg',
      ));
      notifier.stageAttachment(StagedAttachment(
        bytes: Uint8List.fromList([4, 5]),
        mimeType: 'image/png',
        filename: 'b.png',
      ));
      expect(
          container
              .read(askAiChatControllerProvider)
              .stagedAttachments
              .length,
          2);
      notifier.removeStagedAttachment(0);
      final remaining =
          container.read(askAiChatControllerProvider).stagedAttachments;
      expect(remaining.length, 1);
      expect(remaining.first.mimeType, 'image/png');
      // Out-of-bounds index — no-op.
      notifier.removeStagedAttachment(99);
      expect(
          container
              .read(askAiChatControllerProvider)
              .stagedAttachments
              .length,
          1);
    });

    test('stageAttachment caps at maxAttachmentsPerMessage', () async {
      final container = _container(_StubRepo(), _StubSubmit());
      addTearDown(container.dispose);
      final notifier = container.read(askAiChatControllerProvider.notifier);
      for (var i = 0; i < maxAttachmentsPerMessage + 2; i++) {
        notifier.stageAttachment(StagedAttachment(
          bytes: Uint8List.fromList([i]),
          mimeType: 'image/jpeg',
          filename: '$i.jpg',
        ));
      }
      expect(
          container
              .read(askAiChatControllerProvider)
              .stagedAttachments
              .length,
          maxAttachmentsPerMessage);
    });

    test('reset clears state', () async {
      final container = _container(_StubRepo(), _StubSubmit());
      addTearDown(container.dispose);
      final notifier = container.read(askAiChatControllerProvider.notifier);
      await notifier.sendMessage('hi');
      notifier.reset();
      expect(
          container.read(askAiChatControllerProvider).messages, isEmpty);
      expect(
          container.read(askAiChatControllerProvider).conversationId, isNull);
    });

    test('loadConversation replaces messages and seeds linkedReportId',
        () async {
      final repo = _StubRepo();
      final container = _container(repo, _StubSubmit());
      addTearDown(container.dispose);
      await container
          .read(askAiChatControllerProvider.notifier)
          .loadConversation(repo, 'c-9');
      final state = container.read(askAiChatControllerProvider);
      expect(state.conversationId, 'c-9');
      expect(state.messages, hasLength(1));
      expect(state.submittedReportId, 'rep-old');
      expect(repo.loadedId, 'c-9');
    });
  });
}
