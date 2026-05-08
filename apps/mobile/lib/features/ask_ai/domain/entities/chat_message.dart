import 'chat_attachment.dart';

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.intentDetected,
    required this.createdAt,
    this.attachments = const [],
  });

  final String id;
  final ChatRole role;
  final String content;
  final bool intentDetected;
  final DateTime createdAt;
  final List<ChatAttachment> attachments;
}
