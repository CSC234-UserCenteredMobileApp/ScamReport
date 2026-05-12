enum MyReportStatus { pending, verified, rejected, withdrawn }

class MyReport {
  const MyReport({
    required this.id,
    required this.title,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionRemark,
  });

  final String id;
  final String title;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;
  final MyReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionRemark;

  static MyReportStatus _parseStatus(String s) {
    switch (s) {
      case 'verified':
        return MyReportStatus.verified;
      case 'rejected':
        return MyReportStatus.rejected;
      case 'withdrawn':
        return MyReportStatus.withdrawn;
      default:
        return MyReportStatus.pending;
    }
  }

  factory MyReport.fromJson(Map<String, dynamic> json) {
    return MyReport(
      id: json['id'] as String,
      title: json['title'] as String,
      scamTypeCode: json['scamTypeCode'] as String,
      scamTypeLabelEn: json['scamTypeLabelEn'] as String,
      scamTypeLabelTh: json['scamTypeLabelTh'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      rejectionRemark: json['rejectionRemark'] as String?,
    );
  }
}
