import '../ask_ai_repository.dart';
import '../entities/turn_outcome.dart';

/// Sends a chat turn against an existing conversation. If [conversationId]
/// is null, a new conversation is created first (lazy creation pattern —
/// the screen can stay in "empty welcome" state until the user actually
/// sends something).
class SendTurnUseCase {
  SendTurnUseCase(this._repo);
  final AskAiRepository _repo;

  Future<({String conversationId, TurnOutcome outcome})> call({
    String? conversationId,
    required String content,
    List<TurnAttachment> attachments = const [],
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('content must not be empty');
    }
    final id = conversationId ?? await _repo.createConversation();
    final outcome = attachments.isEmpty
        ? await _repo.sendMessage(id, content)
        : await _repo.sendMessageWithAttachments(id, content, attachments);
    return (conversationId: id, outcome: outcome);
  }
}
