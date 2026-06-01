/// Domain mirror of the shared `MatchedScammer` contract
/// (`packages/shared/src/schemas/scammers.ts`). Returned by `/check` when the
/// checked identifier hit a known scammer profile, or when several semantic
/// matches share the same scammer. Pure Dart — no JSON, no Flutter.
class MatchedScammer {
  const MatchedScammer({required this.summary, required this.recentCases});

  final ScammerSummary summary;
  final List<MatchedScammerCase> recentCases;
}

class ScammerSummary {
  const ScammerSummary({
    required this.id,
    required this.displayName,
    required this.aliases,
    required this.riskLevel,
    required this.reportCount,
    required this.topScamTypeCodes,
    this.suspectedName,
    this.person,
  });

  final String id;
  final String displayName;

  /// Name the offender claimed to use. Null for an anonymous campaign.
  final String? suspectedName;

  /// Link to a known human when the campaign is attributable.
  final ScammerPersonRef? person;

  final List<String> aliases;

  /// `'low' | 'medium' | 'high' | 'unknown'`.
  final String riskLevel;

  final int reportCount;
  final List<String> topScamTypeCodes;
}

class ScammerPersonRef {
  const ScammerPersonRef({
    required this.id,
    required this.fullName,
    required this.riskLevel,
    required this.campaignCount,
  });

  final String id;
  final String fullName;
  final String riskLevel;
  final int campaignCount;
}

class MatchedScammerCase {
  const MatchedScammerCase({
    required this.id,
    required this.title,
    required this.scamTypeCode,
    this.verifiedAt,
  });

  final String id;
  final String title;
  final String scamTypeCode;
  final String? verifiedAt;
}
