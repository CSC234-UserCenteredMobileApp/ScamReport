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
  }) {
    return _api.submit(
      draft: draft,
      sourceConversationId: sourceConversationId,
      clientSubmissionId: clientSubmissionId,
    );
  }
}
