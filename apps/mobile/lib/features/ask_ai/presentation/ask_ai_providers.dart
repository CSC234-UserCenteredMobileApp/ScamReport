import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/ask_ai_api_client.dart';
import '../data/ask_ai_repository_impl.dart';
import '../domain/ask_ai_repository.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/turn_outcome.dart';
import '../domain/use_cases/send_turn.dart';

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

/// In-memory chat state. PR-6 will hydrate from /ask-ai/conversations on
/// drawer open; for v1 a fresh chat session starts empty each launch but
/// every turn is persisted server-side, so re-opening a conversation by
/// id later is possible via getConversation.
class AskAiChatState {
  AskAiChatState({
    this.conversationId,
    this.messages = const [],
    this.lastOutcome,
    this.isSending = false,
    this.error,
  });

  final String? conversationId;
  final List<ChatMessage> messages;
  final TurnOutcome? lastOutcome;
  final bool isSending;
  final Object? error;

  AskAiChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    TurnOutcome? lastOutcome,
    bool? isSending,
    Object? error,
    bool clearError = false,
    bool clearOutcome = false,
  }) {
    return AskAiChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      lastOutcome: clearOutcome ? null : (lastOutcome ?? this.lastOutcome),
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AskAiChatController extends StateNotifier<AskAiChatState> {
  AskAiChatController(this._sendTurn) : super(AskAiChatState());

  final SendTurnUseCase _sendTurn;

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final result = await _sendTurn(
        conversationId: state.conversationId,
        content: trimmed,
      );
      state = state.copyWith(
        conversationId: result.conversationId,
        messages: [
          ...state.messages,
          result.outcome.userMessage,
          result.outcome.assistantMessage,
        ],
        lastOutcome: result.outcome,
        isSending: false,
      );
    } catch (err) {
      state = state.copyWith(isSending: false, error: err);
    }
  }

  void reset() {
    state = AskAiChatState();
  }
}

final askAiChatControllerProvider =
    StateNotifierProvider<AskAiChatController, AskAiChatState>((ref) {
  return AskAiChatController(ref.watch(sendTurnUseCaseProvider));
});
