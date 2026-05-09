import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/search/data/search_api.dart';

void main() {
  group('SearchApi.searchReports', () {
    test('returns items list on 200', () async {
      final api = SearchApi(MockClient((_) async => http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'r1',
                  'title': 'Phone scam',
                  'excerpt': 'Caller asking OTP.',
                  'scamTypeCode': 'phone',
                  'scamTypeLabelEn': 'Phone Scam',
                  'scamTypeLabelTh': 'หลอกลวง',
                  'verifiedAt': '2026-05-01T00:00:00.000Z',
                  'reportCount': 2,
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          )));

      final items = await api.searchReports(q: 'phone');
      expect(items, hasLength(1));
      expect((items[0] as Map)['id'], 'r1');
    });

    test('includes q param when provided', () async {
      Uri? captured;
      final api = SearchApi(MockClient((req) async {
        captured = req.url;
        return http.Response(jsonEncode({'items': []}), 200,
            headers: {'content-type': 'application/json'});
      }));

      await api.searchReports(q: 'phishing');
      expect(captured?.queryParameters['q'], 'phishing');
    });

    test('omits q param when null', () async {
      Uri? captured;
      final api = SearchApi(MockClient((req) async {
        captured = req.url;
        return http.Response(jsonEncode({'items': []}), 200,
            headers: {'content-type': 'application/json'});
      }));

      await api.searchReports();
      expect(captured?.queryParameters.containsKey('q'), isFalse);
    });

    test('includes scamTypeCodes param when codes provided', () async {
      Uri? captured;
      final api = SearchApi(MockClient((req) async {
        captured = req.url;
        return http.Response(jsonEncode({'items': []}), 200,
            headers: {'content-type': 'application/json'});
      }));

      await api.searchReports(scamTypeCodes: ['phone', 'phishing']);
      expect(captured?.queryParameters['scamTypeCodes'], 'phone,phishing');
    });

    test('throws on 4xx response', () {
      final api = SearchApi(
          MockClient((_) async => http.Response('bad request', 400)));
      expect(api.searchReports(q: 'test'), throwsA(isA<Exception>()));
    });

    test('throws on 5xx response', () {
      final api = SearchApi(
          MockClient((_) async => http.Response('server error', 500)));
      expect(api.searchReports(), throwsA(isA<Exception>()));
    });
  });

  group('SearchApi.fetchScamTypes', () {
    test('returns items list on 200', () async {
      final api = SearchApi(MockClient((_) async => http.Response(
            jsonEncode({
              'items': [
                {
                  'code': 'phone',
                  'labelEn': 'Phone Scam',
                  'labelTh': 'หลอกลวง',
                  'displayOrder': 1,
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          )));

      final items = await api.fetchScamTypes();
      expect(items, hasLength(1));
      expect((items[0] as Map)['code'], 'phone');
    });

    test('returns empty list when no scam types', () async {
      final api = SearchApi(MockClient((_) async => http.Response(
            jsonEncode({'items': []}),
            200,
            headers: {'content-type': 'application/json'},
          )));

      expect(await api.fetchScamTypes(), isEmpty);
    });

    test('throws on 5xx response', () {
      final api = SearchApi(
          MockClient((_) async => http.Response('error', 503)));
      expect(api.fetchScamTypes(), throwsA(isA<Exception>()));
    });
  });
}
