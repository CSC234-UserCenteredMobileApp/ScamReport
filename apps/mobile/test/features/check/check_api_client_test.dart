import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/check/data/check_api_client.dart';
import 'package:mobile/features/check/domain/check_result.dart';

void main() {
  group('detectType', () {
    test('phone — Thai mobile with country code', () {
      expect(detectType('+66 84 419 2270'), 'phone');
    });

    test('phone — local format 0XX', () {
      expect(detectType('0812345678'), 'phone');
    });

    test('url — http scheme', () {
      expect(detectType('http://bit.ly/example'), 'url');
    });

    test('url — https scheme', () {
      expect(detectType('https://example.com/path'), 'url');
    });

    test('url — www prefix without scheme', () {
      expect(detectType('www.example.com'), 'url');
    });

    test('text — plain message', () {
      expect(detectType('parcel held SMS from Kerry Express'), 'text');
    });

    test('text — short ambiguous string', () {
      expect(detectType('hello'), 'text');
    });
  });

  group('CheckQuery', () {
    test('equality — same payload + type are equal', () {
      // ignore: prefer_const_constructors
      final q1 = CheckQuery(payload: '+66812345678', type: 'phone');
      // ignore: prefer_const_constructors
      final q2 = CheckQuery(payload: '+66812345678', type: 'phone');
      expect(q1, equals(q2));
    });

    test('equality — different type not equal', () {
      // ignore: prefer_const_constructors
      final q1 = CheckQuery(payload: 'test', type: 'phone');
      // ignore: prefer_const_constructors
      final q2 = CheckQuery(payload: 'test', type: 'text');
      expect(q1, isNot(equals(q2)));
    });

    test('hashCode — equal objects share hash', () {
      // ignore: prefer_const_constructors
      final q1 = CheckQuery(payload: 'x', type: 'url');
      // ignore: prefer_const_constructors
      final q2 = CheckQuery(payload: 'x', type: 'url');
      expect(q1.hashCode, equals(q2.hashCode));
    });

    test('source field is optional', () {
      // ignore: prefer_const_constructors
      final q = CheckQuery(
        payload: '+66812345678',
        type: 'phone',
        source: 'clipboard',
      );
      expect(q.source, 'clipboard');
    });
  });

  group('CheckResult', () {
    test('fromCache defaults to false', () {
      // ignore: prefer_const_constructors
      final r = CheckResult(
        verdict: 'safe',
        matchedCount: 0,
        matches: [],
      );
      expect(r.fromCache, isFalse);
    });

    test('fromCache can be set to true', () {
      // ignore: prefer_const_constructors
      final r = CheckResult(
        verdict: 'scam',
        matchedCount: 1,
        matches: const [],
        fromCache: true,
      );
      expect(r.fromCache, isTrue);
    });
  });
}
