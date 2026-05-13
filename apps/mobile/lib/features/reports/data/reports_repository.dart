import 'dart:typed_data';

import '../domain/edit_report_detail.dart';
import '../domain/my_report.dart';
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

  Future<EditReportDetail> getMyReportDetail(String id) async {
    final map = await _api.fetchMyReportDetail(id);
    return EditReportDetail.fromJson(map);
  }

  Future<List<MyReport>> getMyReports() => _api.fetchMyReports();

  Future<({String reportId, DateTime createdAt})> submitReport({
    required String title,
    required String description,
    required String scamTypeCode,
    String? targetIdentifier,
    String? targetIdentifierKind,
    List<Map<String, dynamic>> evidenceFiles = const [],
    String? clientSubmissionId,
  }) =>
      _api.submitReport(
        title: title,
        description: description,
        scamTypeCode: scamTypeCode,
        targetIdentifier: targetIdentifier,
        targetIdentifierKind: targetIdentifierKind,
        evidenceFiles: evidenceFiles,
        clientSubmissionId: clientSubmissionId,
      );

  Future<void> updateReport({
    required String reportId,
    required String title,
    required String description,
    required String scamTypeCode,
    String? targetIdentifier,
    String? targetIdentifierKind,
    List<Map<String, dynamic>> evidenceFiles = const [],
  }) =>
      _api.updateReport(
        reportId: reportId,
        title: title,
        description: description,
        scamTypeCode: scamTypeCode,
        targetIdentifier: targetIdentifier,
        targetIdentifierKind: targetIdentifierKind,
        evidenceFiles: evidenceFiles,
      );

  Future<void> withdrawReport(String reportId) => _api.withdrawReport(reportId);

  Future<Map<String, dynamic>> uploadEvidence({
    required Uint8List bytes,
    required String mimeType,
    required String filename,
  }) =>
      _api.uploadEvidence(bytes: bytes, mimeType: mimeType, filename: filename);
}
