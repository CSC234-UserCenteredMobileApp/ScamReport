import 'dart:typed_data';

import '../entities/ai_draft.dart';

/// Pure-Dart shape for an evidence file the user curated in the editor.
/// Mirrors `StagedAttachment` but lives in the domain layer so the data
/// implementation owns the upload semantics.
class EvidenceFileInput {
  EvidenceFileInput({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });
  final Uint8List bytes;
  final String mimeType;
  final String filename;
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
