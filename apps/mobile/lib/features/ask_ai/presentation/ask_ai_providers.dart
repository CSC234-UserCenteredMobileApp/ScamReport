import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/ask_ai_api_client.dart';
import '../data/ask_ai_repository_impl.dart';
import '../data/attachment_picker.dart';
import '../data/reports_submit_api.dart';
import '../data/submit_drafted_report_impl.dart';
import '../domain/ask_ai_repository.dart';
import '../domain/entities/ai_draft.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/turn_outcome.dart';
import '../domain/use_cases/send_turn.dart';
import '../domain/use_cases/submit_drafted_report.dart';

final askAiApiClientProvider = Provider<AskAiApiClient>((ref) {
  return AskAiApiClient(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final askAiRepositoryProvider = Provider<AskAiRepository>((ref) {
  return AskAiRepositoryImpl(ref.watch(askAiApiClientProvider));
});

final sendTurnUseCaseProvider = Provider<SendTurnUseCase>((ref) {
  return SendTurnUseCase(ref.watch(askAiRepositoryProvider));
});

final reportsSubmitApiProvider = Provider<ReportsSubmitApi>((ref) {
  return ReportsSubmitApi(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final submitDraftedReportProvider = Provider<SubmitDraftedReport>((ref) {
  return SubmitDraftedReportImpl(ref.watch(reportsSubmitApiProvider));
});

final attachmentPickerProvider = Provider<AttachmentPicker>((ref) {
  return AttachmentPicker();
});

final conversationListProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>((ref) async {
  return ref.watch(askAiRepositoryProvider).listConversations();
});

/// In-memory chat state. PR-6 will hydrate from /ask-ai/conversations on
/// drawer open; for v1 a fresh chat session starts empty each launch but
/// every turn is persisted server-side, so re-opening a conversation by
/// id later is possible via getConversation.
class AskAiChatState {
  AskAiChatState({
    this.conversationId,
    this.messages = const [],
    this.lastOutcome,
    this.activeDraft,
    this.activeEvidence,
    this.stagedAttachments = const [],
    this.conversationAttachments = const [],
    this.isSending = false,
    this.isSubmitting = false,
    this.submittedReportId,
    this.error,
  });

  final List<StagedAttachment> stagedAttachments;
  // Cumulative cache: every file the user has attached during this session's
  // chat. Survives the per-turn `stagedAttachments` clear so the editor can
  // pre-fill its evidence list. Reset on `reset()` and `loadConversation()`.
  final List<StagedAttachment> conversationAttachments;
  // Editor-curated evidence. null = user hasn't opened the editor yet, so
  // submit defaults to conversationAttachments. Non-null (incl. empty) =
  // user has explicitly chosen what to attach.
  final List<StagedAttachment>? activeEvidence;

  /// What submitActiveDraft will actually upload. Falls back to the
  /// conversation cumulative cache when the user hasn't curated yet.
  List<StagedAttachment> get effectiveEvidence =>
      activeEvidence ?? conversationAttachments;

  final String? conversationId;
  final List<ChatMessage> messages;
  final TurnOutcome? lastOutcome;
  // The draft currently surfaced to the user. Diverges from
  // `lastOutcome.draft` once the user opens the editor and tweaks fields.
  final AiDraft? activeDraft;
  final bool isSending;
  final bool isSubmitting;
  final String? submittedReportId;
  final Object? error;

  bool get canOfferReport =>
      activeDraft != null &&
      (lastOutcome?.reportable ?? false) &&
      submittedReportId == null;

  AskAiChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    TurnOutcome? lastOutcome,
    AiDraft? activeDraft,
    List<StagedAttachment>? activeEvidence,
    List<StagedAttachment>? stagedAttachments,
    List<StagedAttachment>? conversationAttachments,
    bool? isSending,
    bool? isSubmitting,
    String? submittedReportId,
    Object? error,
    bool clearError = false,
    bool clearOutcome = false,
    bool clearDraft = false,
    bool clearActiveEvidence = false,
    bool clearSubmittedReport = false,
  }) {
    return AskAiChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      lastOutcome: clearOutcome ? null : (lastOutcome ?? this.lastOutcome),
      activeDraft: clearDraft ? null : (activeDraft ?? this.activeDraft),
      activeEvidence: clearActiveEvidence
          ? null
          : (activeEvidence ?? this.activeEvidence),
      stagedAttachments: stagedAttachments ?? this.stagedAttachments,
      conversationAttachments:
          conversationAttachments ?? this.conversationAttachments,
      isSending: isSending ?? this.isSending,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedReportId: clearSubmittedReport
          ? null
          : (submittedReportId ?? this.submittedReportId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AskAiChatController extends StateNotifier<AskAiChatState> {
  AskAiChatController(this._sendTurn, this._submit) : super(AskAiChatState());

  final SendTurnUseCase _sendTurn;
  final SubmitDraftedReport _submit;

  void stageAttachment(StagedAttachment a) {
    if (state.stagedAttachments.length >= maxAttachmentsPerMessage) return;
    state = state.copyWith(
      stagedAttachments: [...state.stagedAttachments, a],
      clearError: true,
    );
  }

  void removeStagedAttachment(int index) {
    final list = [...state.stagedAttachments];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    state = state.copyWith(stagedAttachments: list);
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final attachments = state.stagedAttachments
          .map((s) => TurnAttachment(
                bytes: s.bytes,
                mimeType: s.mimeType,
                filename: s.filename,
              ))
          .toList(growable: false);
      final result = await _sendTurn(
        conversationId: state.conversationId,
        content: trimmed,
        attachments: attachments,
      );
      // Reset the active draft to whatever Gemini just produced — the user
      // might have tweaked an old draft and is now asking the AI to redraft.
      // Move the freshly-sent staged attachments into the cumulative
      // conversation cache so the editor can pre-fill them.
      state = state.copyWith(
        conversationId: result.conversationId,
        messages: [
          ...state.messages,
          result.outcome.userMessage,
          result.outcome.assistantMessage,
        ],
        lastOutcome: result.outcome,
        activeDraft: result.outcome.draft,
        stagedAttachments: const [],
        conversationAttachments: [
          ...state.conversationAttachments,
          ...state.stagedAttachments,
        ],
        isSending: false,
        clearDraft: result.outcome.draft == null,
        // Reset evidence curation on new turn — user might be starting over.
        clearActiveEvidence: true,
      );
    } catch (err) {
      state = state.copyWith(isSending: false, error: err);
    }
  }

  /// Replace the draft fields with user-edited values (DraftEditorSheet).
  /// Optionally also overwrites the evidence list curated in the same sheet.
  void updateDraft(AiDraft updated, {List<StagedAttachment>? evidence}) {
    state = state.copyWith(
      activeDraft: updated,
      activeEvidence: evidence,
    );
  }

  /// Submit the active draft to POST /reports. Sets `submittedReportId` on
  /// success so the chat bubble can announce + deep-link to My Reports.
  ///
  /// Evidence list comes from state.effectiveEvidence (editor-curated when
  /// the user opened the sheet, else the cumulative chat attachments).
  Future<void> submitActiveDraft() async {
    final draft = state.activeDraft;
    final convId = state.conversationId;
    if (draft == null || convId == null || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _submit(
        draft: draft,
        sourceConversationId: convId,
        clientSubmissionId: '$convId-${DateTime.now().millisecondsSinceEpoch}',
        evidenceFiles: state.effectiveEvidence
            .map((s) => EvidenceFileInput(
                  bytes: s.bytes,
                  mimeType: s.mimeType,
                  filename: s.filename,
                ))
            .toList(growable: false),
      );
      state = state.copyWith(
        isSubmitting: false,
        submittedReportId: result.reportId,
      );
    } catch (err) {
      state = state.copyWith(isSubmitting: false, error: err);
    }
  }

  void reset() {
    state = AskAiChatState();
  }

  /// Load a past conversation into the chat panel. Replaces the current
  /// messages list and clears any staged attachments / drafts (those are
  /// per-session and don't survive a swap).
  Future<void> loadConversation(AskAiRepository repo, String conversationId) async {
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final detail = await repo.getConversation(conversationId);
      state = AskAiChatState(
        conversationId: detail.id,
        messages: detail.messages,
        submittedReportId: detail.linkedReportId,
      );
    } catch (err) {
      state = state.copyWith(isSending: false, error: err);
    }
  }
}

final askAiChatControllerProvider =
    StateNotifierProvider<AskAiChatController, AskAiChatState>((ref) {
  return AskAiChatController(
    ref.watch(sendTurnUseCaseProvider),
    ref.watch(submitDraftedReportProvider),
  );
});
