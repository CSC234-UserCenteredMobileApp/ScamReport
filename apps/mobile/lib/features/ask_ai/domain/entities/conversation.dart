import 'chat_message.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.createdAt,
    required this.lastMessageAt,
    required this.preview,
    this.linkedReportId,
  });

  final String id;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String preview;
  final String? linkedReportId;
}

class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.createdAt,
    required this.messages,
    this.linkedReportId,
  });

  final String id;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  final String? linkedReportId;
}
