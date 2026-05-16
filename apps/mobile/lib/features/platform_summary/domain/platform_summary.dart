// Platform Summary domain entity — mirror of the cleaned-up
// `PlatformSummaryResponse` (AI score distribution + latest AI eval were
// removed in the same PR that drops the eval feature). Reporter identity
// is never carried.

class PlatformSummaryRange {
  const PlatformSummaryRange({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}

class PlatformReportTotals {
  const PlatformReportTotals({
    required this.total,
    required this.verified,
    required this.pending,
    required this.rejected,
    required this.flagged,
  });
  final int total;
  final int verified;
  final int pending;
  final int rejected;
  final int flagged;
}

class PlatformScamType {
  const PlatformScamType({
    required this.scamTypeCode,
    required this.labelEn,
    required this.count,
  });
  final String scamTypeCode;
  final String labelEn;
  final int count;
}

class PlatformTopScammer {
  const PlatformTopScammer({
    required this.id,
    required this.displayName,
    required this.suspectedName,
    required this.reportCount,
    required this.riskLevel,
  });
  final String id;
  final String displayName;
  final String? suspectedName;
  final int reportCount;
  final String riskLevel;
}

class PlatformTopIdentifier {
  const PlatformTopIdentifier({
    required this.kind,
    required this.valueNormalized,
    required this.reportCount,
  });
  final String kind;
  final String valueNormalized;
  final int reportCount;
}

class PlatformVerdictMix {
  const PlatformVerdictMix({
    required this.scam,
    required this.suspicious,
    required this.safe,
    required this.unknown,
  });
  final int scam;
  final int suspicious;
  final int safe;
  final int unknown;
}

class PlatformCheckLogs {
  const PlatformCheckLogs({required this.total, required this.verdictMix});
  final int total;
  final PlatformVerdictMix verdictMix;
}

class PlatformSummary {
  const PlatformSummary({
    required this.range,
    required this.reports,
    required this.scamTypeBreakdown,
    required this.topScammers,
    required this.topIdentifiers,
    required this.checkLogs,
    required this.generatedAt,
  });

  final PlatformSummaryRange range;
  final PlatformReportTotals reports;
  final List<PlatformScamType> scamTypeBreakdown;
  final List<PlatformTopScammer> topScammers;
  final List<PlatformTopIdentifier> topIdentifiers;
  final PlatformCheckLogs checkLogs;
  final DateTime generatedAt;
}
