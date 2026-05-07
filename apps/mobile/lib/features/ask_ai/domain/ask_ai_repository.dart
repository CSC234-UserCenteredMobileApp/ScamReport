import 'entities/conversation.dart';
import 'entities/turn_outcome.dart';

/// Repository interface — pure Dart. Implementations go in data/.
abstract class AskAiRepository {
  Future<String> createConversation();
  Future<List<ConversationSummary>> listConversations();
  Future<ConversationDetail> getConversation(String conversationId);
  Future<void> deleteConversation(String conversationId);
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  });
}
