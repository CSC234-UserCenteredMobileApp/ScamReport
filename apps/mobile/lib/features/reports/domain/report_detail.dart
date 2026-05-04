class EvidenceFileItem {
  const EvidenceFileItem({
    required this.id,
    required this.signedUrl,
    required this.kind,
    required this.mimeType,
  });

  final String id;
  final String? signedUrl;
  final String kind; // 'image' | 'pdf'
  final String mimeType;
}

class ReportDetail {
  const ReportDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.verifiedAt,
    required this.reportCount,
    required this.targetIdentifier,
    required this.targetIdentifierKind,
    required this.evidenceFiles,
  });

  final String id;
  final String title;
  final String description;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;
  final DateTime verifiedAt;
  final int reportCount;
  final String? targetIdentifier;
  final String? targetIdentifierKind; // 'phone' | 'url' | 'other'
  final List<EvidenceFileItem> evidenceFiles;
}
