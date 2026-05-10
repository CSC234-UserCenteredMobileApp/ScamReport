import 'dart:typed_data';

import 'entities/conversation.dart';
import 'entities/turn_outcome.dart';

/// A single staged attachment ready to be sent. Pure-Dart shape so the
/// domain layer doesn't depend on image_picker / http types.
class TurnAttachment {
  TurnAttachment({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });
  final Uint8List bytes;
  final String mimeType;
  final String filename;
}

/// Repository interface — pure Dart. Implementations go in data/.
abstract class AskAiRepository {
  Future<String> createConversation();
  Future<List<ConversationSummary>> listConversations();
  Future<ConversationDetail> getConversation(String conversationId);
  Future<void> deleteConversation(String conversationId);

  /// Text-only path (PR-3 schema kept for backward compat).
  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  });

  /// Multipart path — uploads each attachment alongside the text content.
  Future<TurnOutcome> sendMessageWithAttachments(
    String conversationId,
    String content,
    List<TurnAttachment> attachments,
  );

  /// PATCH the per-conversation draft server-side (cross-device sync).
  /// Pass `null` to clear the draft. iter-5.
  Future<void> upsertDraft(String conversationId, PersistedDraft? payload);
}
