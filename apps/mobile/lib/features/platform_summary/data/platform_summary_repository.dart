// Maps the platform-summary JSON into the domain entity. Re-uses
// `ModApiClient.fetchPlatformSummary` so the mobile admin surface keeps a
// single HTTP gateway for moderator concerns.

import '../../moderation/data/mod_api_client.dart';
import '../domain/platform_summary.dart';

class PlatformSummaryRepository {
  PlatformSummaryRepository(this._api);

  final ModApiClient _api;

  Future<PlatformSummary> getSummary() async {
    final raw = await _api.fetchPlatformSummary();
    final range = raw['range'] as Map<String, dynamic>;
    final reports = raw['reports'] as Map<String, dynamic>;
    final checkLogs = raw['checkLogs'] as Map<String, dynamic>;
    final verdictMix = checkLogs['verdictMix'] as Map<String, dynamic>;
    return PlatformSummary(
      range: PlatformSummaryRange(
        from: DateTime.parse(range['from'] as String),
        to: DateTime.parse(range['to'] as String),
      ),
      reports: PlatformReportTotals(
        total: reports['total'] as int,
        verified: reports['verified'] as int,
        pending: reports['pending'] as int,
        rejected: reports['rejected'] as int,
        flagged: reports['flagged'] as int,
      ),
      scamTypeBreakdown: (raw['scamTypeBreakdown'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((m) => PlatformScamType(
                scamTypeCode: m['scamTypeCode'] as String,
                labelEn: m['labelEn'] as String,
                count: m['count'] as int,
              ))
          .toList(),
      topScammers: (raw['topScammers'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((m) => PlatformTopScammer(
                id: m['id'] as String,
                displayName: m['displayName'] as String,
                suspectedName: m['suspectedName'] as String?,
                reportCount: m['reportCount'] as int,
                riskLevel: m['riskLevel'] as String,
              ))
          .toList(),
      topIdentifiers: (raw['topIdentifiers'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((m) => PlatformTopIdentifier(
                kind: m['kind'] as String,
                valueNormalized: m['valueNormalized'] as String,
                reportCount: m['reportCount'] as int,
              ))
          .toList(),
      checkLogs: PlatformCheckLogs(
        total: checkLogs['total'] as int,
        verdictMix: PlatformVerdictMix(
          scam: verdictMix['scam'] as int,
          suspicious: verdictMix['suspicious'] as int,
          safe: verdictMix['safe'] as int,
          unknown: verdictMix['unknown'] as int,
        ),
      ),
      generatedAt: DateTime.parse(raw['generatedAt'] as String),
    );
  }
}
