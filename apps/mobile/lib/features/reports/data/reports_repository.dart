import '../domain/report_detail.dart';
import 'reports_api.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ReportsApi _api;

  Future<ReportDetail> getReportDetail(String id) async {
    final map = await _api.fetchReportDetail(id);
    final rawFiles = map['evidenceFiles'] as List<dynamic>;
    return ReportDetail(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      scamTypeCode: map['scamTypeCode'] as String,
      scamTypeLabelEn: map['scamTypeLabelEn'] as String,
      scamTypeLabelTh: map['scamTypeLabelTh'] as String,
      verifiedAt: DateTime.parse(map['verifiedAt'] as String),
      reportCount: map['reportCount'] as int,
      targetIdentifier: map['targetIdentifier'] as String?,
      targetIdentifierKind: map['targetIdentifierKind'] as String?,
      evidenceFiles: rawFiles.map((f) {
        final file = f as Map<String, dynamic>;
        return EvidenceFileItem(
          id: file['id'] as String,
          signedUrl: file['signedUrl'] as String?,
          kind: file['kind'] as String,
          mimeType: file['mimeType'] as String,
        );
      }).toList(),
    );
  }
}
