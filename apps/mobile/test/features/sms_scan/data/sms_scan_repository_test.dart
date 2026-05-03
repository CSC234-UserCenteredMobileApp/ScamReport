import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/cache/app_database.dart' as $db;
import 'package:mobile/features/sms_scan/data/sms_event_channel.dart';
import 'package:mobile/features/sms_scan/data/sms_scan_repository.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late http.Client mockClient;
  late $db.AppDatabase db;
  late SmsScanRepository repo;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = _MockHttpClient();
    db = $db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = SmsScanRepository(http: mockClient, db: db);
  });

  tearDown(() async => db.close());

  group('processEvent', () {
    test('stores alert and returns it when verdict is scam', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'verdict': 'scam', 'matchedCount': 3, 'matches': []}),
            200,
          ));

      final event = SmsEvent(sender: '+66812345678', body: 'Click this link now!');
      final result = await repo.processEvent(event);

      expect(result, isNotNull);
      expect(result!.verdict, 'scam');
      expect(result.senderMasked, contains('5678'));
      expect(result.bodyExcerpt, 'Click this link now!');

      final stored = await repo.listAlerts();
      expect(stored, hasLength(1));
      expect(stored.first.verdict, 'scam');
    });

    test('stores alert and returns it when verdict is suspicious', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'verdict': 'suspicious', 'matchedCount': 1, 'matches': []}),
            200,
          ));

      final event = SmsEvent(sender: '+66898765432', body: 'Please verify your account');
      final result = await repo.processEvent(event);

      expect(result, isNotNull);
      expect(result!.verdict, 'suspicious');

      final stored = await repo.listAlerts();
      expect(stored, hasLength(1));
    });

    test('returns null and does not store when verdict is safe', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'verdict': 'safe', 'matchedCount': 0, 'matches': []}),
            200,
          ));

      final event = SmsEvent(sender: '+66812345678', body: 'Your OTP is 123456');
      final result = await repo.processEvent(event);

      expect(result, isNull);
      final stored = await repo.listAlerts();
      expect(stored, isEmpty);
    });

    test('returns null when API call fails', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('error', 500));

      final event = SmsEvent(sender: '+66812345678', body: 'Test');
      final result = await repo.processEvent(event);

      expect(result, isNull);
      final stored = await repo.listAlerts();
      expect(stored, isEmpty);
    });

    test('truncates bodyExcerpt to 80 chars', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'verdict': 'scam', 'matchedCount': 1, 'matches': []}),
            200,
          ));

      final longBody = 'A' * 200;
      final event = SmsEvent(sender: '+66812345678', body: longBody);
      final result = await repo.processEvent(event);

      expect(result!.bodyExcerpt.length, 80);
    });
  });

  group('maskSender', () {
    test('masks all but last 4 digits', () {
      expect(SmsScanRepository.maskSender('+66812345678'), 'XXXX-5678');
      expect(SmsScanRepository.maskSender('0812345678'), 'XXXX-5678');
    });

    test('returns sender unchanged when fewer than 4 digits', () {
      expect(SmsScanRepository.maskSender('123'), '123');
    });
  });
}
