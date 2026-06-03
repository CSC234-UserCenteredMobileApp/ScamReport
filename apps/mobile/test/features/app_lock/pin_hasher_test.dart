import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_lock/data/pin_hasher.dart';

// Converts a hex string ("12ab...") into a byte list for comparing against
// the published PBKDF2-HMAC-SHA256 test vectors.
List<int> _hex(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i += 2) {
    out.add(int.parse(s.substring(i, i + 2), radix: 16));
  }
  return out;
}

void main() {
  group('pbkdf2Sha256 (known-answer vectors)', () {
    // Standard PBKDF2-HMAC-SHA256 vectors: P="password", S="salt", dkLen=32.
    test('c=1 matches the published vector', () {
      final out = pbkdf2Sha256(
        utf8.encode('password'),
        utf8.encode('salt'),
        1,
        32,
      );
      expect(
        out,
        _hex('120fb6cffcf8b32c43e7225256c4f837'
            'a86548c92ccc35480805987cb70be17b'),
      );
    });

    test('c=2 matches the published vector', () {
      final out = pbkdf2Sha256(
        utf8.encode('password'),
        utf8.encode('salt'),
        2,
        32,
      );
      expect(
        out,
        _hex('ae4d0c95af6b46d32d0adff928f06dd0'
            '2a303f8ef3c251dfd6e2d85a95474c43'),
      );
    });

    test('c=4096 matches the published vector', () {
      final out = pbkdf2Sha256(
        utf8.encode('password'),
        utf8.encode('salt'),
        4096,
        32,
      );
      expect(
        out,
        _hex('c5e478d59288c841aa530db6845c4c8d'
            '962893a001ce4e11a4963873aa98134a'),
      );
    });
  });

  group('hashNewPin / pinMatches roundtrip', () {
    test('correct PIN verifies against its own hash', () {
      final encoded = hashNewPin('123456');
      expect(pinMatches((pin: '123456', encoded: encoded)), isTrue);
    });

    test('wrong PIN does not verify', () {
      final encoded = hashNewPin('123456');
      expect(pinMatches((pin: '000000', encoded: encoded)), isFalse);
    });

    test('hashing the same PIN twice yields different output (unique salt)', () {
      final a = hashNewPin('424242');
      final b = hashNewPin('424242');
      expect(a, isNot(equals(b)));
      // ...but both still verify the original PIN.
      expect(pinMatches((pin: '424242', encoded: a)), isTrue);
      expect(pinMatches((pin: '424242', encoded: b)), isTrue);
    });

    test('encoded format is pbkdf2\$<iters>\$<salt>\$<hash>', () {
      final encoded = hashNewPin('654321');
      final parts = encoded.split(r'$');
      expect(parts.length, 4);
      expect(parts[0], 'pbkdf2');
      expect(int.parse(parts[1]), greaterThan(0));
    });

    test('malformed encoded string never matches', () {
      expect(pinMatches((pin: '123456', encoded: 'garbage')), isFalse);
      expect(pinMatches((pin: '123456', encoded: 'pbkdf2\$1\$only')), isFalse);
      expect(pinMatches((pin: '123456', encoded: '')), isFalse);
    });
  });
}
