import 'ai_draft.dart';
import 'chat_attachment.dart';
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

/// In-progress draft persisted server-side for cross-device sync (iter-5).
class PersistedDraft {
  const PersistedDraft({
    required this.draft,
    required this.userEditedDraft,
    required this.evidenceAttachmentIds,
  });

  final AiDraft draft;
  final bool userEditedDraft;
  final List<String> evidenceAttachmentIds;
}

class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.createdAt,
    required this.messages,
    this.linkedReportId,
    this.draft,
    this.evidenceAttachments = const [],
  });

  final String id;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  final String? linkedReportId;
  // Server-persisted draft + curated evidence references for this conversation.
  // null when no draft exists. iter-5 cross-device sync.
  final PersistedDraft? draft;
  // Hydrated metadata for `draft.evidenceAttachmentIds` so the editor can
  // render restored evidence by signedUrl without raw bytes.
  final List<ChatAttachment> evidenceAttachments;
}
