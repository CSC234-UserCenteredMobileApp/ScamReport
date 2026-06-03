import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Default PBKDF2 work factor. A 6-digit PIN is only a 10^6 keyspace, so the
/// real defence is the OS keystore (FlutterSecureStorage) plus the attempt
/// lockout — this iteration count is defence-in-depth, not the primary guard.
/// Deriving a hash at this cost runs in tens of milliseconds, so callers should
/// invoke [hashNewPin] / [pinMatches] off the UI isolate via `compute`.
const int kPinHashIterations = 100000;

const int _saltBytes = 16;
const int _keyBytes = 32; // SHA-256 digest length.

/// PBKDF2 with HMAC-SHA256 (RFC 8018 / PKCS#5 v2.1).
///
/// Pure function — deterministic for a given (password, salt, iterations,
/// keyLength). Validated against the published SHA-256 test vectors.
Uint8List pbkdf2Sha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  final blocks = (keyLength / _keyBytes).ceil();
  final derived = Uint8List(blocks * _keyBytes);

  for (var block = 1; block <= blocks; block++) {
    // U_1 = PRF(password, salt || INT_32_BE(block))
    final blockIndex = Uint8List(4)
      ..[0] = (block >> 24) & 0xff
      ..[1] = (block >> 16) & 0xff
      ..[2] = (block >> 8) & 0xff
      ..[3] = block & 0xff;

    var u = Uint8List.fromList(hmac.convert([...salt, ...blockIndex]).bytes);
    final t = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    derived.setRange((block - 1) * _keyBytes, block * _keyBytes, t);
  }

  return Uint8List.sublistView(derived, 0, keyLength);
}

/// Cryptographically-random 16-byte salt, base64-encoded.
String generateSalt() {
  final rng = Random.secure();
  final bytes = Uint8List(_saltBytes);
  for (var i = 0; i < _saltBytes; i++) {
    bytes[i] = rng.nextInt(256);
  }
  return base64.encode(bytes);
}

/// Derives the encoded hash string for a PIN against a known salt + work
/// factor. Format: `pbkdf2$<iterations>$<saltB64>$<hashB64>`.
String _encode({
  required String pin,
  required String saltB64,
  required int iterations,
}) {
  final derived = pbkdf2Sha256(
    utf8.encode(pin),
    base64.decode(saltB64),
    iterations,
    _keyBytes,
  );
  return 'pbkdf2\$$iterations\$$saltB64\$${base64.encode(derived)}';
}

/// Hashes a fresh PIN with a random salt at the default work factor.
///
/// Top-level + single-argument so it can be handed to `compute`.
String hashNewPin(String pin) {
  return _encode(
    pin: pin,
    saltB64: generateSalt(),
    iterations: kPinHashIterations,
  );
}

/// Verifies a PIN against a previously-[hashNewPin]ed encoded string.
///
/// Returns false for any malformed input. Top-level + single record argument
/// so it can be handed to `compute`.
bool pinMatches(({String pin, String encoded}) args) {
  final parts = args.encoded.split(r'$');
  if (parts.length != 4 || parts[0] != 'pbkdf2') return false;

  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations <= 0) return false;

  final String candidate;
  try {
    candidate = _encode(
      pin: args.pin,
      saltB64: parts[2],
      iterations: iterations,
    );
  } on FormatException {
    return false; // Salt wasn't valid base64.
  }
  return _constantTimeEquals(candidate, args.encoded);
}

/// Abstraction over PIN hashing so the repository can be tested without paying
/// the PBKDF2 cost. The production implementation runs the derivation on a
/// background isolate.
abstract class PinHasher {
  Future<String> hash(String pin);
  Future<bool> verify(String pin, String encoded);
}

/// Production [PinHasher] — derives on a background isolate via `compute` so
/// the 100k-iteration PBKDF2 never blocks the UI thread.
class Pbkdf2PinHasher implements PinHasher {
  const Pbkdf2PinHasher();

  @override
  Future<String> hash(String pin) => compute(hashNewPin, pin);

  @override
  Future<bool> verify(String pin, String encoded) =>
      compute(pinMatches, (pin: pin, encoded: encoded));
}

/// Length-then-byte comparison that does not short-circuit on the first
/// differing byte, to avoid leaking match progress via timing.
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
