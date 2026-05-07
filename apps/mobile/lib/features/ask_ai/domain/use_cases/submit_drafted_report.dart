import '../entities/ai_draft.dart';

/// Submit a drafted report. The data layer talks to POST /reports and links
/// `ai_conversations.linked_report_id` server-side. Throws an AskAiFailure
/// on error; on success returns the new report id + timestamp.
abstract class SubmitDraftedReport {
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
  });
}
