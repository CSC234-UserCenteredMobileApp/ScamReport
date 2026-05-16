// =============================================================================
// Moderation domain entities
// =============================================================================
//
// Reporter identity is intentionally absent from every entity in this file
// (PRD v1.2 FR-7.4 + FR-7.8). Admin views never display the reporter — not as
// a UUID, not as an email, not as a masked handle. The `reporters` linkage is
// retained server-side in `reports.reporter_id` for legal traceability and
// FCM fan-out only; it never crosses the API boundary into mobile entities.

class ModQueueItem {
  const ModQueueItem({
    required this.id,
    required this.title,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.submittedAt,
    required this.status,
    required this.priorityFlag,
    required this.evidenceCount,
    this.lastRemarkByAdmin,
    this.aiScore,
    this.aiConfidence,
  });

  final String id;
  final String title;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;
  final DateTime submittedAt;
  final String status;
  final bool priorityFlag;
  final int evidenceCount;
  final String? lastRemarkByAdmin;
  final int? aiScore;
  final String? aiConfidence;

  bool get isFlagged => status == 'flagged';
}

class EvidenceFile {
  const EvidenceFile({
    required this.id,
    required this.storagePath,
    required this.signedUrl,
    required this.kind,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String id;
  final String storagePath;
  final String? signedUrl;
  final String kind;
  final String mimeType;
  final int sizeBytes;
}

class ModerationAction {
  const ModerationAction({
    required this.action,
    required this.remark,
    required this.createdAt,
    this.adminId,
  });

  // adminId is admin-to-admin transparency (FR-7.6); not a reporter-identity
  // surface. Allowed in admin views.
  final String? adminId;
  final String action;
  final String remark;
  final DateTime createdAt;
}

class ModReportDetail {
  const ModReportDetail({
    required this.id,
    required this.title,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.submittedAt,
    required this.status,
    required this.priorityFlag,
    required this.evidenceCount,
    required this.description,
    required this.targetIdentifier,
    required this.targetIdentifierKind,
    required this.evidenceFiles,
    required this.duplicateCount,
    required this.auditTrail,
    this.lastRemarkByAdmin,
    this.aiScore,
    this.aiConfidence,
    this.suspectedNameAtSubmit,
  });

  final String id;
  final String title;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;
  final DateTime submittedAt;
  final String status;
  final bool priorityFlag;
  final int evidenceCount;
  final String description;
  final String? targetIdentifier;
  final String? targetIdentifierKind;
  final List<EvidenceFile> evidenceFiles;
  final int duplicateCount;
  final List<ModerationAction> auditTrail;
  final String? lastRemarkByAdmin;
  final int? aiScore;
  final String? aiConfidence;
  /// Name the reporter (or Ask AI) attributed to the caller at submit time.
  /// Independent of any linked scammer profile.
  final String? suspectedNameAtSubmit;

  bool get isFlagged => status == 'flagged';
  bool get isPending => status == 'pending';
}

class ModQueueData {
  const ModQueueData({
    required this.items,
    required this.pendingCount,
    required this.flaggedCount,
  });

  final List<ModQueueItem> items;
  final int pendingCount;
  final int flaggedCount;
}
