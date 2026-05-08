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
    // Upload each evidence file sequentially to keep memory + concurrent
    // request count low. v1 cap is 5 files so this is bounded.
    final uploaded = <EvidenceMetadata>[];
    for (final f in evidenceFiles) {
      final meta = await _api.uploadEvidence(
        bytes: f.bytes,
        mimeType: f.mimeType,
        filename: f.filename,
      );
      uploaded.add(meta);
    }
    return _api.submit(
      draft: draft,
      sourceConversationId: sourceConversationId,
      clientSubmissionId: clientSubmissionId,
      evidenceFiles: uploaded,
    );
  }
}
