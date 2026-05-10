import '../domain/entities/ai_draft.dart';
import '../domain/use_cases/submit_drafted_report.dart';
import 'reports_submit_api.dart';

class SubmitDraftedReportImpl implements SubmitDraftedReport {
  SubmitDraftedReportImpl(this._api);
  final ReportsSubmitApi _api;

  @override
  Future<({String reportId, DateTime createdAt})> call({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
    List<EvidenceFileInput> evidenceFiles = const [],
  }) async {
    // Split evidence into two pipelines:
    //  • Local bytes (chatAttachmentId == null) → POST /reports/evidence to
    //    upload + collect EvidenceMetadata.
    //  • Restored evidence (chatAttachmentId != null) → already lives in
    //    chat-attachments bucket. Pass the id so the server promotes it
    //    into the evidence bucket inside the create-report transaction.
    final uploaded = <EvidenceMetadata>[];
    final promotedIds = <String>[];
    for (final f in evidenceFiles) {
      if (f.chatAttachmentId != null) {
        promotedIds.add(f.chatAttachmentId!);
      } else {
        final meta = await _api.uploadEvidence(
          bytes: f.bytes,
          mimeType: f.mimeType,
          filename: f.filename,
        );
        uploaded.add(meta);
      }
    }
    return _api.submit(
      draft: draft,
      sourceConversationId: sourceConversationId,
      clientSubmissionId: clientSubmissionId,
      evidenceFiles: uploaded,
      promotedEvidenceAttachmentIds: promotedIds,
    );
  }
}
