import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/call_screening/data/call_screening_api_client.dart';
import 'package:mobile/features/call_screening/data/call_screening_repository_impl.dart';

CallScreeningRepositoryImpl _makeRepo({
  List<String> phones = const [],
  Map<String, Object> prefValues = const {},
}) {
  final client = MockClient((_) async => http.Response(
        jsonEncode({
          'phones': phones,
          'updatedAt': '2026-05-01T00:00:00.000Z',
        }),
        200,
      ));
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(prefValues));
  final prefs = SharedPreferences.getInstance();
  late SharedPreferences prefsInstance;
  prefs.then((p) => prefsInstance = p);

  // Synchronous access after future completes in test pump
  return CallScreeningRepositoryImpl(
    apiClient: CallScreeningApiClient(
      client: client,
      baseUrl: 'http://localhost:3000',
    ),
    prefs: prefsInstance,
  );
}

void main() {
  group('CallScreeningRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('syncPhoneList stores phones in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'phones': ['+66811111111', '+66822222222'],
              'updatedAt': '2026-05-01T00:00:00.000Z',
            }),
            200,
          ));
      final repo = CallScreeningRepositoryImpl(
        apiClient: CallScreeningApiClient(
          client: client,
          baseUrl: 'http://localhost:3000',
        ),
        prefs: prefs,
      );

      await repo.syncPhoneList();

      final stored = prefs.getString('scam_phones');
      expect(stored, isNotNull);
      final decoded = jsonDecode(stored!) as List;
      expect(decoded, containsAll(['+66811111111', '+66822222222']));
    });

    test('getBlockedCalls returns empty list when no log exists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = CallScreeningRepositoryImpl(
        apiClient: CallScreeningApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          baseUrl: 'http://localhost:3000',
        ),
        prefs: prefs,
      );

      final calls = await repo.getBlockedCalls();

      expect(calls, isEmpty);
    });

    test('getBlockedCalls parses stored log and sorts newest first', () async {
      final log = jsonEncode([
        {'number': '+66811111111', 'blockedAt': 1000},
        {'number': '+66822222222', 'blockedAt': 2000},
      ]);
      SharedPreferences.setMockInitialValues({'blocked_calls': log});
      final prefs = await SharedPreferences.getInstance();
      final repo = CallScreeningRepositoryImpl(
        apiClient: CallScreeningApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          baseUrl: 'http://localhost:3000',
        ),
        prefs: prefs,
      );

      final calls = await repo.getBlockedCalls();

      expect(calls.length, 2);
      // Newest first
      expect(calls.first.number, '+66822222222');
      expect(calls.last.number, '+66811111111');
    });

    test('setEnabled and isEnabled round-trip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = CallScreeningRepositoryImpl(
        apiClient: CallScreeningApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          baseUrl: 'http://localhost:3000',
        ),
        prefs: prefs,
      );

      expect(await repo.isEnabled(), isFalse);

      await repo.setEnabled(true);
      expect(await repo.isEnabled(), isTrue);

      await repo.setEnabled(false);
      expect(await repo.isEnabled(), isFalse);
    });
  });
}
