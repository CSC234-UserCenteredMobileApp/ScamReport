import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/home/data/home_api.dart';

void main() {
  group('HomeApi.fetchStats', () {
    test('returns parsed map on 200', () async {
      final body = jsonEncode({'data': {
        'verifiedTotal': 100, 'newThisWeek': 5,
        'topScamTypeLabelEn': 'Phishing', 'topScamTypeLabelTh': 'Phishing TH',
      }});
      final api = HomeApi(MockClient((_) async =>
          http.Response.bytes(utf8.encode(body), 200)));

      final result = await api.fetchStats();
      expect(result['data'], isA<Map>());
    });

    test('throws on 5xx', () {
      final api = HomeApi(MockClient((_) async => http.Response('error', 503)));
      expect(api.fetchStats(), throwsA(isA<Exception>()));
    });

    test('throws on 4xx', () {
      final api = HomeApi(MockClient((_) async => http.Response('bad', 400)));
      expect(api.fetchStats(), throwsA(isA<Exception>()));
    });
  });

  group('HomeApi.fetchRecentAlerts', () {
    test('returns list on 200', () async {
      final api = HomeApi(MockClient((_) async => http.Response(
            jsonEncode({'items': [{'id': 'a1'}]}),
            200,
          )));

      final result = await api.fetchRecentAlerts();
      expect(result, hasLength(1));
    });

    test('returns empty list for empty items', () async {
      final api = HomeApi(MockClient((_) async => http.Response(
            jsonEncode({'items': <dynamic>[]}),
            200,
          )));

      expect(await api.fetchRecentAlerts(), isEmpty);
    });

    test('throws on 5xx', () {
      final api = HomeApi(MockClient((_) async => http.Response('error', 500)));
      expect(api.fetchRecentAlerts(), throwsA(isA<Exception>()));
    });
  });

  group('HomeApi.fetchRecentReports', () {
    test('returns list on 200', () async {
      final api = HomeApi(MockClient((_) async => http.Response(
            jsonEncode({'items': [{'id': 'r1'}]}),
            200,
          )));

      final result = await api.fetchRecentReports();
      expect(result, hasLength(1));
    });

    test('throws on 5xx', () {
      final api = HomeApi(MockClient((_) async => http.Response('error', 500)));
      expect(api.fetchRecentReports(), throwsA(isA<Exception>()));
    });
  });
}
