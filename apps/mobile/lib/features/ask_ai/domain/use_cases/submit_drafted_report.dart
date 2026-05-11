import 'dart:typed_data';

import '../entities/ai_draft.dart';

/// Pure-Dart shape for an evidence file the user curated in the editor.
/// Mirrors `StagedAttachment` but lives in the domain layer so the data
/// implementation owns the upload semantics.
///
/// When `chatAttachmentId` is non-null, the file is already in the
/// chat-attachments bucket (from a restored draft). The data impl skips the
/// upload step and asks the server to promote it into the evidence bucket
/// via `promotedEvidenceAttachmentIds`. iter-5 server-side draft sync.
class EvidenceFileInput {
  EvidenceFileInput({
    required this.bytes,
    required this.mimeType,
    required this.filename,
    this.chatAttachmentId,
  });
  final Uint8List bytes;
  final String mimeType;
  final String filename;
  final String? chatAttachmentId;
}

/// Submit a drafted report. The data layer talks to POST /reports and links
/// `ai_conversations.linked_report_id` server-side. Throws an AskAiFailure
/// on error; on success returns the new report id + timestamp.
abstract class SubmitDraftedReport {
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
    List<EvidenceFileInput> evidenceFiles = const [],
  });
}
