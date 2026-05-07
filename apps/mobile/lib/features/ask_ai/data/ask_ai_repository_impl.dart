import '../domain/ask_ai_repository.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/turn_outcome.dart';
import 'ask_ai_api_client.dart';

class AskAiRepositoryImpl implements AskAiRepository {
  AskAiRepositoryImpl(this._api);
  final AskAiApiClient _api;

  @override
  Future<String> createConversation() => _api.createConversation();

  @override
  Future<List<ConversationSummary>> listConversations() =>
      _api.listConversations();

  @override
  Future<ConversationDetail> getConversation(String conversationId) =>
      _api.getConversation(conversationId);

  @override
  Future<void> deleteConversation(String conversationId) =>
      _api.deleteConversation(conversationId);

  @override
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) =>
      _api.sendMessage(conversationId, content, attachmentIds: attachmentIds);
}
