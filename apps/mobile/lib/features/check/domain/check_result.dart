class CheckQuery {
  const CheckQuery({
    required this.payload,
    required this.type,
    this.source,
  });

  final String payload;
  final String type; // 'phone' | 'url' | 'text'
  final String? source; // 'manual' | 'clipboard' | 'share'

  @override
  bool operator ==(Object other) =>
      other is CheckQuery && other.payload == payload && other.type == type;

  @override
  int get hashCode => Object.hash(payload, type);
}

class ReportSummaryItem {
  const ReportSummaryItem({
    required this.id,
    required this.title,
    required this.scamType,
    required this.verifiedAt,
  });

  final String id;
  final String title;
  final String scamType;
  final String verifiedAt;
}

class CheckResult {
  const CheckResult({
    required this.verdict,
    required this.matchedCount,
    required this.matches,
    this.fromCache = false,
  });

  final String verdict; // 'scam' | 'suspicious' | 'safe' | 'unknown'
  final int matchedCount;
  final List<ReportSummaryItem> matches;
  final bool fromCache;
}
