import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/share_target/domain/share_input.dart';

void main() {
  group('ShareInput.detectKind', () {
    test('phone — Thai mobile with country code', () {
      expect(ShareInput.detectKind('+66812345678'), 'phone');
    });

    test('phone — local 0XX format', () {
      expect(ShareInput.detectKind('0812345678'), 'phone');
    });

    test('phone — with spaces and dashes', () {
      expect(ShareInput.detectKind('+66 81 234 5678'), 'phone');
    });

    test('phone — with parentheses', () {
      expect(ShareInput.detectKind('(02) 123-4567'), 'phone');
    });

    test('url — https scheme', () {
      expect(ShareInput.detectKind('https://example.com/path'), 'url');
    });

    test('url — http scheme', () {
      expect(ShareInput.detectKind('http://bit.ly/scam'), 'url');
    });

    test('text — plain scam message', () {
      expect(ShareInput.detectKind('Your parcel is held. Click here to claim.'), 'text');
    });

    test('text — short ambiguous string', () {
      expect(ShareInput.detectKind('hello'), 'text');
    });

    test('strips leading/trailing whitespace before detecting', () {
      expect(ShareInput.detectKind('  +66812345678  '), 'phone');
    });

    test('empty string → text', () {
      expect(ShareInput.detectKind(''), 'text');
    });
  });

  group('ShareInput constructor', () {
    test('stores text and kind', () {
      const input = ShareInput(text: '+66812345678', kind: 'phone');
      expect(input.text, '+66812345678');
      expect(input.kind, 'phone');
    });
  });
}
