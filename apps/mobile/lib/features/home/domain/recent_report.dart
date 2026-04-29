class RecentReport {
  const RecentReport({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.verifiedAt,
    required this.reportCount,
  });
  final String id;
  final String title;
  final String excerpt;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;
  final DateTime verifiedAt;
  final int reportCount;
}
