import '../domain/matched_scammer.dart';

/// Single source of truth for (de)serialising [MatchedScammer] JSON.
///
/// Used by BOTH the API parser ([CheckApiClient]) and the on-device cache
/// ([CheckRepositoryImpl]). Keeping one mapper is deliberate: the original bug
/// was the two paths drifting and silently dropping `matchedScammer`.
/// The JSON shape mirrors the shared contract `MatchedScammer`
/// (`packages/shared/src/schemas/scammers.ts`).
MatchedScammer? matchedScammerFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final summaryJson = raw['summary'];
  if (summaryJson is! Map<String, dynamic>) return null;

  final personJson = summaryJson['person'];
  final cases = (raw['recentCases'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((c) => MatchedScammerCase(
            id: c['id'] as String,
            title: c['title'] as String,
            scamTypeCode: c['scamTypeCode'] as String,
            verifiedAt: c['verifiedAt'] as String?,
          ))
      .toList();

  return MatchedScammer(
    summary: ScammerSummary(
      id: summaryJson['id'] as String,
      displayName: summaryJson['displayName'] as String,
      suspectedName: summaryJson['suspectedName'] as String?,
      person: personJson is Map<String, dynamic>
          ? ScammerPersonRef(
              id: personJson['id'] as String,
              fullName: personJson['fullName'] as String,
              riskLevel: personJson['riskLevel'] as String,
              campaignCount: (personJson['campaignCount'] as num).toInt(),
            )
          : null,
      aliases: (summaryJson['aliases'] as List<dynamic>? ?? const [])
          .map((a) => a as String)
          .toList(),
      riskLevel: summaryJson['riskLevel'] as String,
      reportCount: (summaryJson['reportCount'] as num).toInt(),
      topScamTypeCodes:
          (summaryJson['topScamTypeCodes'] as List<dynamic>? ?? const [])
              .map((s) => s as String)
              .toList(),
    ),
    recentCases: cases,
  );
}

Map<String, dynamic>? matchedScammerToJson(MatchedScammer? m) {
  if (m == null) return null;
  final s = m.summary;
  return {
    'summary': {
      'id': s.id,
      'displayName': s.displayName,
      'suspectedName': s.suspectedName,
      'person': s.person == null
          ? null
          : {
              'id': s.person!.id,
              'fullName': s.person!.fullName,
              'riskLevel': s.person!.riskLevel,
              'campaignCount': s.person!.campaignCount,
            },
      'aliases': s.aliases,
      'riskLevel': s.riskLevel,
      'reportCount': s.reportCount,
      'topScamTypeCodes': s.topScamTypeCodes,
    },
    'recentCases': m.recentCases
        .map((c) => {
              'id': c.id,
              'title': c.title,
              'scamTypeCode': c.scamTypeCode,
              'verifiedAt': c.verifiedAt,
            })
        .toList(),
  };
}
