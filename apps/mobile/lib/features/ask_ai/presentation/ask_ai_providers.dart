import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../../../core/di/cache.dart';
import '../data/ask_ai_api_client.dart';
import '../data/ask_ai_persistence.dart';
import '../data/ask_ai_repository_impl.dart';
import '../data/ask_ai_state_codec.dart';
import '../data/attachment_picker.dart';
import '../data/reports_submit_api.dart';
import '../data/submit_drafted_report_impl.dart';
import '../domain/ask_ai_repository.dart';
import '../domain/entities/ai_draft.dart';
import '../domain/entities/chat_attachment.dart';
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

final askAiPersistenceProvider = Provider<AskAiPersistence>((ref) {
  return AskAiPersistence(ref.watch(appDatabaseProvider));
});

final conversationListProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>((ref) async {
  return ref.watch(askAiRepositoryProvider).listConversations();
});

/// A previous send that failed, captured so the retry banner can re-play
/// the same content + bytes without forcing the user to re-type / re-pick.
class FailedSendAttempt {
  FailedSendAttempt({required this.content, required this.attachments});
  final String content;
  final List<StagedAttachment> attachments;
}

/// In-memory chat state. Critical fields (draft, evidence, staged,
/// conversationAttachments, conversationId) are debounced-persisted to drift
/// so they survive an app kill — see iter-3 plan.
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
    this.lastFailedAttempt,
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
  // Set when the most recent sendMessage threw — drives the retry banner.
  // Cleared whenever a new send starts.
  final FailedSendAttempt? lastFailedAttempt;

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
    FailedSendAttempt? lastFailedAttempt,
    bool clearError = false,
    bool clearOutcome = false,
    bool clearDraft = false,
    bool clearActiveEvidence = false,
    bool clearSubmittedReport = false,
    bool clearLastFailedAttempt = false,
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
      lastFailedAttempt: clearLastFailedAttempt
          ? null
          : (lastFailedAttempt ?? this.lastFailedAttempt),
    );
  }
}

class AskAiChatController extends StateNotifier<AskAiChatState> {
  AskAiChatController(
    this._sendTurn,
    this._submit,
    this._persistence,
    this._repo,
  ) : super(AskAiChatState()) {
    _loadFromCache();
  }

  final SendTurnUseCase _sendTurn;
  final SubmitDraftedReport _submit;
  final AskAiPersistence _persistence;
  final AskAiRepository _repo;
  Timer? _saveDebounce;

  static const _saveDelay = Duration(milliseconds: 500);

  Future<void> _loadFromCache() async {
    final cached = await _persistence.load();
    if (cached == null) return;
    // Replay the persisted snapshot. Don't blow away anything the user has
    // typed in the half-second since launch (rare race).
    state = state.copyWith(
      conversationId: cached.conversationId,
      activeDraft: cached.activeDraft,
      activeEvidence: cached.activeEvidence,
      stagedAttachments: cached.stagedAttachments,
      conversationAttachments: cached.conversationAttachments,
    );
    final convId = cached.conversationId;
    if (convId != null) {
      // Refresh the message list from the server so the user sees their
      // saved chat. Failure is non-fatal — the persisted draft + evidence
      // still surface; we just won't have history loaded.
      try {
        final detail = await _repo.getConversation(convId);
        state = state.copyWith(
          messages: detail.messages,
          submittedReportId: detail.linkedReportId,
        );
      } catch (_) {
        // Likely 404 — conversation deleted on the server. Drop the dangling
        // id so the next send creates a fresh conversation.
        state = state.copyWith(conversationId: null);
      }
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDelay, () {
      _persistence.save(
        AskAiPersistedState(
          conversationId: state.conversationId,
          activeDraft: state.activeDraft,
          activeEvidence: state.activeEvidence,
          stagedAttachments: state.stagedAttachments,
          conversationAttachments: state.conversationAttachments,
        ),
      );
    });
  }

  @override
  set state(AskAiChatState next) {
    super.state = next;
    _scheduleSave();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

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
    if (state.isSending) return;
    if (trimmed.isEmpty && state.stagedAttachments.isEmpty) return;

    // Build the optimistic user-bubble + clear the composer chip strip
    // immediately so the UI never shows the "stuck chip" gap during the
    // network round-trip.
    final stagedSnapshot = List<StagedAttachment>.unmodifiable(
      state.stagedAttachments,
    );
    final tempId =
        'temp-${DateTime.now().microsecondsSinceEpoch}-${state.messages.length}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      role: ChatRole.user,
      content: trimmed,
      intentDetected: false,
      createdAt: DateTime.now(),
      attachments: [
        for (final s in stagedSnapshot)
          ChatAttachment(
            id: 'temp-att-${s.bytes.hashCode}',
            mimeType: s.mimeType,
            sizeBytes: s.sizeBytes,
            localBytes: s.bytes,
          ),
      ],
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMessage],
      stagedAttachments: const [],
      isSending: true,
      clearError: true,
      clearLastFailedAttempt: true,
    );

    try {
      final attachments = stagedSnapshot
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
      // Replace the optimistic message with the server-returned one (which
      // has the real id + signedUrl on each attachment), then append the
      // assistant reply.
      final swapped = state.messages
          .where((m) => m.id != tempId)
          .toList(growable: true)
        ..add(result.outcome.userMessage)
        ..add(result.outcome.assistantMessage);
      state = state.copyWith(
        conversationId: result.conversationId,
        messages: swapped,
        lastOutcome: result.outcome,
        activeDraft: result.outcome.draft,
        conversationAttachments: [
          ...state.conversationAttachments,
          ...stagedSnapshot,
        ],
        isSending: false,
        clearDraft: result.outcome.draft == null,
        clearActiveEvidence: true,
      );
    } catch (err) {
      // Optimistic bubble persists in messages — keeps user's transcript
      // honest. Capture the attempt so the retry banner can re-play.
      state = state.copyWith(
        isSending: false,
        error: err,
        lastFailedAttempt: FailedSendAttempt(
          content: trimmed,
          attachments: stagedSnapshot,
        ),
      );
    }
  }

  /// Replays the most recent failed sendMessage. Re-stages the bytes and
  /// fires sendMessage with the same content. Optimistic bubble from the
  /// failed attempt stays in the chat list above the retry — user's
  /// transcript is honest about what they tried.
  Future<void> retryLastFailedSend() async {
    final attempt = state.lastFailedAttempt;
    if (attempt == null || state.isSending) return;
    state = state.copyWith(
      stagedAttachments: attempt.attachments,
      clearError: true,
    );
    await sendMessage(attempt.content);
  }

  /// Replace the draft fields with user-edited values (DraftEditorSheet).
  /// Optionally also overwrites the evidence list curated in the same sheet.
  void updateDraft(AiDraft updated, {List<StagedAttachment>? evidence}) {
    state = state.copyWith(
      activeDraft: updated,
      activeEvidence: evidence,
    );
  }

  /// Submit the active draft to POST /reports.
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
      // Submit succeeded — drop the persisted snapshot so a kill+reopen
      // doesn't surface a stale draft.
      _saveDebounce?.cancel();
      unawaited(_persistence.clear());
    } catch (err) {
      state = state.copyWith(isSubmitting: false, error: err);
    }
  }

  void reset() {
    state = AskAiChatState();
    _saveDebounce?.cancel();
    unawaited(_persistence.clear());
  }

  /// Load a past conversation into the chat panel.
  Future<void> loadConversation(AskAiRepository repo, String conversationId) async {
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final detail = await repo.getConversation(conversationId);
      state = AskAiChatState(
        conversationId: detail.id,
        messages: detail.messages,
        submittedReportId: detail.linkedReportId,
      );
      // Different conversation — drop any stale persisted snapshot from a
      // previous session.
      _saveDebounce?.cancel();
      unawaited(_persistence.clear());
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
    ref.watch(askAiPersistenceProvider),
    ref.watch(askAiRepositoryProvider),
  );
});

// Helper used by tests + bubble widgets — keeps `Uint8List` import here so
// the entity file stays minimal.
typedef OptimisticBytes = Uint8List;
