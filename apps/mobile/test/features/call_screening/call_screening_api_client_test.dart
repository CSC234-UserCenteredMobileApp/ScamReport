import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/call_screening/data/call_screening_api_client.dart';

void main() {
  group('CallScreeningApiClient', () {
    test('fetchScamPhones returns phone list on 200', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'phones': ['+66812345678', '+66898765432'],
              'updatedAt': '2026-05-01T00:00:00.000Z',
            }),
            200,
          ));

      final api = CallScreeningApiClient(
        client: client,
        baseUrl: 'http://localhost:3000',
      );

      final phones = await api.fetchScamPhones();

      expect(phones, ['+66812345678', '+66898765432']);
    });

    test('fetchScamPhones returns empty list when phones array is empty',
        () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'phones': [], 'updatedAt': '2026-05-01T00:00:00.000Z'}),
            200,
          ));

      final api = CallScreeningApiClient(
        client: client,
        baseUrl: 'http://localhost:3000',
      );

      final phones = await api.fetchScamPhones();

      expect(phones, isEmpty);
    });

    test('fetchScamPhones throws on non-200 status', () async {
      final client = MockClient(
        (_) async => http.Response('Internal Server Error', 500),
      );

      final api = CallScreeningApiClient(
        client: client,
        baseUrl: 'http://localhost:3000',
      );

      expect(() => api.fetchScamPhones(), throwsException);
    });

    test('fetchScamPhones calls correct endpoint', () async {
      Uri? capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(
          jsonEncode({'phones': [], 'updatedAt': '2026-05-01T00:00:00.000Z'}),
          200,
        );
      });

      final api = CallScreeningApiClient(
        client: client,
        baseUrl: 'http://localhost:3000',
      );

      await api.fetchScamPhones();

      expect(capturedUri?.path, '/check/phones');
    });
  });
}
