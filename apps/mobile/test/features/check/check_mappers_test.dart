import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/check/data/check_mappers.dart';

/// Regression tests for the bug where `matchedScammer` was silently dropped:
/// the API built a scammer profile that never reached the UI or the cache.
/// These lock in that the field survives parse and a cache round-trip.
void main() {
  // Mirrors the shared `MatchedScammer` contract shape.
  // Typed <String, dynamic> to mirror what jsonDecode produces at runtime
  // (so values can legitimately be null).
  Map<String, dynamic> sampleJson() => <String, dynamic>{
        'summary': <String, dynamic>{
          'id': 'scammer-1',
          'displayName': 'Revenue Dept Impersonator',
          'suspectedName': 'Revenue Department officer',
          'person': <String, dynamic>{
            'id': 'person-1',
            'fullName': 'John Doe',
            'riskLevel': 'high',
            'campaignCount': 3,
          },
          'aliases': ['Tax Office', 'Gov Refund'],
          'riskLevel': 'high',
          'reportCount': 7,
          'topScamTypeCodes': ['phone_impersonation', 'phishing_sms'],
        },
        'recentCases': [
          <String, dynamic>{
            'id': 'rep-1',
            'title': 'Fake tax fine call',
            'scamTypeCode': 'phone_impersonation',
            'verifiedAt': '2026-05-01T10:00:00.000Z',
          },
          <String, dynamic>{
            'id': 'rep-2',
            'title': 'Refund link SMS',
            'scamTypeCode': 'phishing_sms',
            'verifiedAt': null,
          },
        ],
      };

  group('matchedScammerFromJson', () {
    test('parses the full contract shape', () {
      final m = matchedScammerFromJson(sampleJson())!;
      expect(m.summary.id, 'scammer-1');
      expect(m.summary.displayName, 'Revenue Dept Impersonator');
      expect(m.summary.suspectedName, 'Revenue Department officer');
      expect(m.summary.riskLevel, 'high');
      expect(m.summary.reportCount, 7);
      expect(m.summary.aliases, ['Tax Office', 'Gov Refund']);
      expect(
          m.summary.topScamTypeCodes, ['phone_impersonation', 'phishing_sms']);
      expect(m.summary.person!.fullName, 'John Doe');
      expect(m.summary.person!.campaignCount, 3);
      expect(m.recentCases.length, 2);
      expect(m.recentCases.first.title, 'Fake tax fine call');
      expect(m.recentCases.last.verifiedAt, isNull);
    });

    test('returns null for null / absent input', () {
      expect(matchedScammerFromJson(null), isNull);
      expect(matchedScammerFromJson('not a map'), isNull);
    });

    test('handles a null person', () {
      final json = sampleJson();
      (json['summary'] as Map<String, dynamic>)['person'] = null;
      final m = matchedScammerFromJson(json)!;
      expect(m.summary.person, isNull);
    });
  });

  group('round-trip (parse -> toJson -> parse)', () {
    test('preserves every field through the cache mapper', () {
      final original = matchedScammerFromJson(sampleJson())!;
      final reparsed = matchedScammerFromJson(matchedScammerToJson(original))!;

      expect(reparsed.summary.id, original.summary.id);
      expect(reparsed.summary.displayName, original.summary.displayName);
      expect(reparsed.summary.suspectedName, original.summary.suspectedName);
      expect(reparsed.summary.riskLevel, original.summary.riskLevel);
      expect(reparsed.summary.reportCount, original.summary.reportCount);
      expect(reparsed.summary.aliases, original.summary.aliases);
      expect(
          reparsed.summary.topScamTypeCodes, original.summary.topScamTypeCodes);
      expect(reparsed.summary.person!.id, original.summary.person!.id);
      expect(reparsed.recentCases.length, original.recentCases.length);
      expect(reparsed.recentCases.last.verifiedAt, isNull);
    });

    test('toJson of null is null', () {
      expect(matchedScammerToJson(null), isNull);
    });
  });
}
