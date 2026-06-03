import 'chat_attachment.dart';
import 'similar_report.dart';

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.intentDetected,
    required this.createdAt,
    this.attachments = const [],
    this.similarReports = const [],
    this.searchIntent = false,
  });

  final String id;
  final ChatRole role;
  final String content;
  final bool intentDetected;
  final DateTime createdAt;
  final List<ChatAttachment> attachments;

  /// True when this assistant turn answered a report lookup (search mode).
  /// Drives the cards-section label ("Reports I found" vs "Matched verified
  /// reports"). Always false for user messages and reloaded history.
  final bool searchIntent;

  /// Verified-report cards the AI surfaced alongside this assistant turn.
  /// Always empty for user messages and for assistant messages reloaded
  /// from server history (cards aren't persisted on `ai_messages` — they
  /// only attach to messages received in the live turn response).
  final List<SimilarReport> similarReports;
}
