/// A compact verified-report card the Ask AI service attaches to an
/// assistant turn. Renders inside `_MessageBubble` as a tappable cue —
/// "here are reports we already verified that match what you described."
///
/// Reporter identity is intentionally absent (PRD FR-7.4 + FR-7.8). The
/// shared TypeBox schema enforces it at the type level; the API serializer
/// enforces it at the data level.
class SimilarReport {
  const SimilarReport({
    required this.id,
    required this.title,
    required this.scamTypeCode,
    required this.scamTypeLabelEn,
    required this.scamTypeLabelTh,
    required this.verifiedAt,
  });

  final String id;
  final String title;
  final String scamTypeCode;
  final String scamTypeLabelEn;
  final String scamTypeLabelTh;

  /// ISO-8601 timestamp when the report transitioned to verified. Null is
  /// theoretically possible when the response is from a stale cache; the
  /// card hides the date row in that case.
  final DateTime? verifiedAt;

  factory SimilarReport.fromJson(Map<String, dynamic> j) => SimilarReport(
        id: j['id'] as String,
        title: j['title'] as String,
        scamTypeCode: j['scamTypeCode'] as String,
        scamTypeLabelEn: j['scamTypeLabelEn'] as String,
        scamTypeLabelTh: j['scamTypeLabelTh'] as String,
        verifiedAt: j['verifiedAt'] == null
            ? null
            : DateTime.parse(j['verifiedAt'] as String),
      );
}
