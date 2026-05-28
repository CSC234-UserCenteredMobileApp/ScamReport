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
  ConversationDetail? conversationToReturn;

  @override
  Future<String> createConversation() async => 'c-1';

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    return conversationToReturn ??
        ConversationDetail(
          id: conversationId,
          createdAt: DateTime(2026, 5, 7),
          messages: const [],
        );
  }

  @override
  Future<List<ConversationSummary>> listConversations() async => const [];

  @override
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) async =>
      next ?? _basic(content, draft: _aiDraft);

  @override
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List attachments,
  ) async =>
      next ?? _basic(content, draft: _aiDraft);

  final List<({String conversationId, PersistedDraft? payload})> draftUpserts =
      [];

  @override
  Future<void> upsertDraft(
      String conversationId, PersistedDraft? payload) async {
    draftUpserts.add((conversationId: conversationId, payload: payload));
  }
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
    loaded = state;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    loaded = null;
  }

  @override
  Future<void> clearForUser(String userId) async {
    clearCalls++;
    loaded = null;
  }
}

const _aiDraft = AiDraft(
  title: 'AI suggested title here',
  description: 'AI generated description that is long enough.',
  scamTypeCode: 'phishing_sms',
);

const _userEditedDraft = AiDraft(
  title: 'My edited title',
  description: 'My edited description that is long enough.',
  scamTypeCode: 'phishing_sms',
);

TurnOutcome _basic(String content, {AiDraft? draft, bool reportable = true}) =>
    TurnOutcome(
      userMessage: ChatMessage(
        id: 'real-user',
        role: ChatRole.user,
        content: content,
        intentDetected: true,
        createdAt: DateTime(2026, 5, 7),
      ),
      assistantMessage: ChatMessage(
        id: 'real-assistant',
        role: ChatRole.assistant,
        content: 'reply',
        intentDetected: true,
        createdAt: DateTime(2026, 5, 7),
      ),
      intentDetected: true,
      reportable: reportable,
      hasEnoughInfo: reportable,
      similarReports: const [],
      draft: draft,
    );

ProviderContainer _container({
  required _StubRepo repo,
  AskAiPersistence? persistence,
}) =>
    ProviderContainer(overrides: [
      askAiRepositoryProvider.overrideWithValue(repo),
      sendTurnUseCaseProvider.overrideWith((ref) => SendTurnUseCase(repo)),
      submitDraftedReportProvider.overrideWithValue(_StubSubmit()),
      askAiPersistenceProvider
          .overrideWithValue(persistence ?? _StubPersistence()),
    ]);

void main() {
  group('redraft preservation', () {
    test('user edits to activeDraft survive a follow-up sendMessage', () async {
      final repo = _StubRepo();
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      final notifier = container.read(askAiChatControllerProvider.notifier);

      // Initial AI turn produces a draft.
      await notifier.sendMessage('I got a phishing SMS');
      expect(
        container.read(askAiChatControllerProvider).activeDraft?.title,
        _aiDraft.title,
      );

      // User edits the draft via the editor.
      notifier.updateDraft(_userEditedDraft);
      expect(
        container.read(askAiChatControllerProvider).userEditedDraft,
        isTrue,
      );

      // Second AI turn ("Ask AI to redraft") returns a fresh draft, but the
      // user's edited title MUST NOT be replaced.
      repo.next = _basic(
        'redraft please',
        draft: const AiDraft(
          title: 'NEW AI suggested title',
          description: 'NEW AI description that is long.',
          scamTypeCode: 'fake_qr',
        ),
      );
      await notifier.sendMessage('redraft please');

      final state = container.read(askAiChatControllerProvider);
      expect(state.activeDraft?.title, _userEditedDraft.title);
      expect(state.activeDraft?.scamTypeCode, _userEditedDraft.scamTypeCode);
    });

    test(
      'activeEvidence persists across sendMessage turns (no longer cleared)',
      () async {
        final repo = _StubRepo();
        final container = _container(repo: repo);
        addTearDown(container.dispose);
        final notifier = container.read(askAiChatControllerProvider.notifier);

        await notifier.sendMessage('initial');

        final curated = [
          StagedAttachment(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'image/jpeg',
            filename: 'a.jpg',
          ),
        ];
        notifier.updateDraft(_userEditedDraft, evidence: curated);
        expect(
          container.read(askAiChatControllerProvider).activeEvidence,
          isNotNull,
        );

        await notifier.sendMessage('redraft please');

        // Evidence list survives — iter-4 dropped clearActiveEvidence on
        // turn success.
        final state = container.read(askAiChatControllerProvider);
        expect(state.activeEvidence, isNotNull);
        expect(state.activeEvidence, hasLength(1));
      },
    );

    test(
      'when user has not edited, AI redraft DOES replace the draft',
      () async {
        final repo = _StubRepo();
        final container = _container(repo: repo);
        addTearDown(container.dispose);
        final notifier = container.read(askAiChatControllerProvider.notifier);

        await notifier.sendMessage('initial');
        expect(
          container.read(askAiChatControllerProvider).userEditedDraft,
          isFalse,
        );

        repo.next = _basic(
          'redraft',
          draft: const AiDraft(
            title: 'NEW AI title from second turn',
            description: 'NEW AI description that is long.',
            scamTypeCode: 'fake_qr',
          ),
        );
        await notifier.sendMessage('redraft');
        expect(
          container.read(askAiChatControllerProvider).activeDraft?.title,
          'NEW AI title from second turn',
        );
      },
    );
  });

  group('per-conversation restore (server-side)', () {
    test(
      'loadConversation hydrates activeDraft from server detail.draft',
      () async {
        final stub = _StubPersistence();
        final repo = _StubRepo()
          ..conversationToReturn = ConversationDetail(
            id: 'c-9',
            createdAt: DateTime(2026, 5, 7),
            messages: const [],
            draft: const PersistedDraft(
              draft: _userEditedDraft,
              userEditedDraft: true,
              evidenceAttachmentIds: [],
            ),
            evidenceAttachments: const [],
          );
        final container = _container(repo: repo, persistence: stub);
        addTearDown(container.dispose);
        final notifier = container.read(askAiChatControllerProvider.notifier);

        await notifier.loadConversation(repo, 'c-9');

        final state = container.read(askAiChatControllerProvider);
        expect(state.conversationId, 'c-9');
        expect(state.activeDraft?.title, _userEditedDraft.title);
        expect(state.userEditedDraft, isTrue);
      },
    );

    test(
      'loadConversation with no server draft → state.activeDraft is null',
      () async {
        final stub = _StubPersistence();
        final repo = _StubRepo()
          ..conversationToReturn = ConversationDetail(
            id: 'c-9',
            createdAt: DateTime(2026, 5, 7),
            messages: const [],
            draft: null,
            evidenceAttachments: const [],
          );
        final container = _container(repo: repo, persistence: stub);
        addTearDown(container.dispose);
        final notifier = container.read(askAiChatControllerProvider.notifier);

        await notifier.loadConversation(repo, 'c-9');

        final state = container.read(askAiChatControllerProvider);
        expect(state.conversationId, 'c-9');
        expect(state.activeDraft, isNull);
      },
    );
  });
}
