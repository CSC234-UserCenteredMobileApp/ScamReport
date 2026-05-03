import '../domain/mod_report.dart';
import '../domain/mod_repository.dart';
import 'mod_api_client.dart';

class ModRepositoryImpl implements ModRepository {
  ModRepositoryImpl(this._api);

  final ModApiClient _api;

  @override
  Future<ModQueueData> getQueue() async {
    final raw = await _api.fetchQueue();
    return ModQueueData(
      items: (raw['items'] as List<dynamic>)
          .map((e) => _mapItem(e as Map<String, dynamic>))
          .toList(),
      pendingCount: raw['pendingCount'] as int,
      flaggedCount: raw['flaggedCount'] as int,
    );
  }

  @override
  Future<ModReportDetail> getDetail(String reportId) async {
    final raw = await _api.fetchDetail(reportId);
    return _mapDetail(raw['report'] as Map<String, dynamic>);
  }

  @override
  Future<void> approve(String id, String remark) =>
      _api.postAction(id, 'approve', remark);

  @override
  Future<void> reject(String id, String remark) =>
      _api.postAction(id, 'reject', remark);

  @override
  Future<void> flag(String id, String remark) =>
      _api.postAction(id, 'flag', remark);

  @override
  Future<void> unflag(String id, String remark) =>
      _api.postAction(id, 'unflag', remark);

  ModQueueItem _mapItem(Map<String, dynamic> m) => ModQueueItem(
        id: m['id'] as String,
        title: m['title'] as String,
        scamTypeCode: m['scamTypeCode'] as String,
        scamTypeLabelEn: m['scamTypeLabelEn'] as String,
        scamTypeLabelTh: m['scamTypeLabelTh'] as String,
        submittedAt: DateTime.parse(m['submittedAt'] as String),
        status: m['status'] as String,
        priorityFlag: m['priorityFlag'] as bool,
        evidenceCount: m['evidenceCount'] as int,
        reporterHandle: m['reporterHandle'] as String,
        lastRemarkByAdmin: m['lastRemarkByAdmin'] as String?,
      );

  ModReportDetail _mapDetail(Map<String, dynamic> m) => ModReportDetail(
        id: m['id'] as String,
        title: m['title'] as String,
        scamTypeCode: m['scamTypeCode'] as String,
        scamTypeLabelEn: m['scamTypeLabelEn'] as String,
        scamTypeLabelTh: m['scamTypeLabelTh'] as String,
        submittedAt: DateTime.parse(m['submittedAt'] as String),
        status: m['status'] as String,
        priorityFlag: m['priorityFlag'] as bool,
        evidenceCount: m['evidenceCount'] as int,
        description: m['description'] as String,
        targetIdentifier: m['targetIdentifier'] as String?,
        targetIdentifierKind: m['targetIdentifierKind'] as String?,
        evidenceFiles: (m['evidenceFiles'] as List<dynamic>)
            .map((e) => _mapEvidence(e as Map<String, dynamic>))
            .toList(),
        duplicateCount: m['duplicateCount'] as int,
        auditTrail: (m['auditTrail'] as List<dynamic>)
            .map((e) => _mapAction(e as Map<String, dynamic>))
            .toList(),
        reporterHandle: m['reporterHandle'] as String,
        lastRemarkByAdmin: m['lastRemarkByAdmin'] as String?,
        aiScore: m['aiScore'] as int?,
        aiConfidence: m['aiConfidence'] as String?,
      );

  EvidenceFile _mapEvidence(Map<String, dynamic> m) => EvidenceFile(
        id: m['id'] as String,
        storagePath: m['storagePath'] as String,
        kind: m['kind'] as String,
        mimeType: m['mimeType'] as String,
        sizeBytes: m['sizeBytes'] as int,
      );

  ModerationAction _mapAction(Map<String, dynamic> m) => ModerationAction(
        adminId: m['adminId'] as String?,
        action: m['action'] as String,
        remark: m['remark'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
