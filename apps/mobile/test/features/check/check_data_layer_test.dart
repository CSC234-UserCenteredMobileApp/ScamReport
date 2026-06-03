// Data-layer coverage for the check feature: CheckApiClient (HTTP + parse)
// and CheckRepositoryImpl (drift read-through cache + eviction).
import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/cache/app_database.dart';
import 'package:mobile/features/check/data/check_api_client.dart';
import 'package:mobile/features/check/data/check_repository_impl.dart';
import 'package:mobile/features/check/domain/check_result.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckApiClient extends Mock implements CheckApiClient {}

Map<String, dynamic> _apiBody({bool withScammer = false}) => {
      'verdict': 'scam',
      'matchedCount': 1,
      'matches': [
        {
          'id': 'r1',
          'title': 'Fake parcel SMS',
          'scamType': 'sms_phishing',
          'verifiedAt': '2026-05-30T00:00:00.000Z',
        },
      ],
      'matchedScammer': withScammer
          ? {
              'summary': {
                'id': 's1',
                'displayName': '081-234-5678',
                'suspectedName': 'Somchai S.',
                'person': null,
                'aliases': <String>[],
                'riskLevel': 'high',
                'reportCount': 12,
                'topScamTypeCodes': ['sms_phishing'],
              },
              'recentCases': [
                {
                  'id': 'c1',
                  'title': 'Loan app scam',
                  'scamTypeCode': 'loan_scam',
                  'verifiedAt': '2026-05-01T00:00:00.000Z',
                },
              ],
            }
          : null,
    };

const _query = CheckQuery(payload: '0812345678', type: 'phone');

void main() {
  setUpAll(() {
    registerFallbackValue(_query);
  });

  group('CheckApiClient', () {
    test('POSTs /check and parses a 200 with matchedScammer', () async {
      late http.Request seen;
      final api = CheckApiClient(MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode(_apiBody(withScammer: true)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }));

      final result = await api.check(
        const CheckQuery(payload: '0812345678', type: 'phone', source: 'share'),
      );

      expect(seen.method, 'POST');
      expect(seen.url.path, '/check');
      final sentBody = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(sentBody['type'], 'phone');
      expect(sentBody['payload'], '0812345678');
      expect((sentBody['meta'] as Map<String, dynamic>)['source'], 'share');

      expect(result.verdict, 'scam');
      expect(result.matchedCount, 1);
      expect(result.matches.single.title, 'Fake parcel SMS');
      expect(result.matchedScammer, isNotNull);
      expect(result.matchedScammer!.summary.displayName, '081-234-5678');
      expect(result.matchedScammer!.recentCases.single.id, 'c1');
    });

    test('omits meta entirely when source is null', () async {
      late http.Request seen;
      final api = CheckApiClient(MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode(_apiBody()), 200,
            headers: {'content-type': 'application/json'});
      }));

      final result = await api.check(_query);

      final sentBody = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(sentBody.containsKey('meta'), isFalse);
      expect(result.matchedScammer, isNull);
    });

    test('throws on a non-2xx response', () async {
      final api = CheckApiClient(
        MockClient((_) async => http.Response('boom', 500)),
      );
      expect(() => api.check(_query), throwsA(isA<Exception>()));
    });
  });

  group('CheckRepositoryImpl', () {
    late AppDatabase db;
    late MockCheckApiClient api;
    late CheckRepositoryImpl repo;

    const apiResult = CheckResult(
      verdict: 'scam',
      matchedCount: 1,
      matches: [
        ReportSummaryItem(
          id: 'r1',
          title: 'Fake parcel SMS',
          scamType: 'sms_phishing',
          verifiedAt: '2026-05-30T00:00:00.000Z',
        ),
      ],
    );

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      api = MockCheckApiClient();
      repo = CheckRepositoryImpl(api, db);
    });

    tearDown(() => db.close());

    test('cache miss fetches from the API and persists the entry', () async {
      when(() => api.check(any())).thenAnswer((_) async => apiResult);

      final result = await repo.runCheck(_query);

      expect(result.fromCache, isFalse);
      expect(result.verdict, 'scam');
      verify(() => api.check(any())).called(1);

      final rows = await db.select(db.cacheEntries).get();
      expect(rows.single.key, 'check:phone:0812345678');
    });

    test('cache hit returns fromCache=true without calling the API', () async {
      when(() => api.check(any())).thenAnswer((_) async => apiResult);
      await repo.runCheck(_query); // prime the cache
      clearInteractions(api);

      final second = await repo.runCheck(_query);

      expect(second.fromCache, isTrue);
      expect(second.verdict, 'scam');
      expect(second.matches.single.id, 'r1');
      verifyNever(() => api.check(any()));
    });

    test('cache key trims the payload (same trimmed input hits)', () async {
      when(() => api.check(any())).thenAnswer((_) async => apiResult);
      await repo.runCheck(_query);
      clearInteractions(api);

      final padded = await repo.runCheck(
        const CheckQuery(payload: '  0812345678  ', type: 'phone'),
      );

      expect(padded.fromCache, isTrue);
      verifyNever(() => api.check(any()));
    });

    test('matchedScammer survives the cache round-trip', () async {
      // Build a result carrying a scammer through the real API parser, then
      // drive the repo with it so the cache serialises/deserialises it.
      final parsedApi = CheckApiClient(MockClient((_) async => http.Response(
            jsonEncode(_apiBody(withScammer: true)),
            200,
            headers: {'content-type': 'application/json'},
          )));
      final parsed = await parsedApi.check(_query);

      when(() => api.check(any())).thenAnswer((_) async => parsed);
      await repo.runCheck(_query); // writes scammer JSON to the cache
      clearInteractions(api);

      final cached = await repo.runCheck(_query);
      expect(cached.fromCache, isTrue);
      expect(cached.matchedScammer, isNotNull);
      expect(cached.matchedScammer!.summary.id, 's1');
    });

    test('evicts the oldest check entries above 100', () async {
      // Seed 101 aged cache rows directly.
      for (var i = 0; i < 101; i++) {
        await db.into(db.cacheEntries).insertOnConflictUpdate(
              CacheEntriesCompanion(
                key: Value('check:phone:seed$i'),
                value: Value(jsonEncode({
                  'verdict': 'safe',
                  'matchedCount': 0,
                  'matches': <Object>[],
                  'matchedScammer': null,
                })),
                updatedAt: Value(
                  DateTime(2026, 1, 1).add(Duration(minutes: i)),
                ),
              ),
            );
      }
      when(() => api.check(any())).thenAnswer((_) async => apiResult);

      await repo.runCheck(_query); // 102nd entry -> evicts down to 100

      final rows = await db.select(db.cacheEntries).get();
      expect(rows.length, 100);
      final keys = rows.map((r) => r.key).toSet();
      expect(keys.contains('check:phone:seed0'), isFalse); // oldest gone
      expect(keys.contains('check:phone:0812345678'), isTrue); // newest kept
    });
  });
}
