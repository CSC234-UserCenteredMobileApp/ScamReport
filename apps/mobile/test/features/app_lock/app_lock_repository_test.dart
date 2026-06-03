import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/app_lock/data/app_lock_repository_impl.dart';
import 'package:mobile/features/app_lock/data/pin_hasher.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuth extends Mock implements LocalAuthentication {}

/// Deterministic, cheap stand-in for the real PBKDF2 hasher (which is already
/// validated in pin_hasher_test). Keeps repository tests fast.
class FakeHasher implements PinHasher {
  // base64 so the encoded form never literally contains the plaintext PIN —
  // lets the "no plaintext persisted" assertion stay meaningful.
  String _encode(String pin) => 'fake:${base64.encode(utf8.encode(pin))}';
  @override
  Future<String> hash(String pin) async => _encode(pin);
  @override
  Future<bool> verify(String pin, String encoded) async =>
      encoded == _encode(pin);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  late MockSecureStorage secure;
  late MockLocalAuth localAuth;
  late SharedPreferences prefs;
  late AppLockRepositoryImpl repo;

  // In-memory secure-storage backing map so reads see prior writes/deletes.
  late Map<String, String> store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    secure = MockSecureStorage();
    localAuth = MockLocalAuth();
    store = {};

    when(() => secure.read(key: any(named: 'key')))
        .thenAnswer((inv) async => store[inv.namedArguments[#key]]);
    when(() => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((inv) async {
      store[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(() => secure.delete(key: any(named: 'key')))
        .thenAnswer((inv) async => store.remove(inv.namedArguments[#key]));

    repo = AppLockRepositoryImpl(
      secure: secure,
      prefs: prefs,
      localAuth: localAuth,
      hasher: FakeHasher(),
    );
  });

  group('config persistence', () {
    test('defaults: disabled, no biometric, no pin, 1-minute timeout',
        () async {
      final config = await repo.loadConfig();
      expect(config.enabled, isFalse);
      expect(config.biometricEnabled, isFalse);
      expect(config.pinSet, isFalse);
      expect(config.backgroundTimeout, const Duration(minutes: 1));
    });

    test('enabled + biometric flags round-trip through prefs', () async {
      await repo.setEnabled(true);
      await repo.setBiometricEnabled(true);
      final config = await repo.loadConfig();
      expect(config.enabled, isTrue);
      expect(config.biometricEnabled, isTrue);
    });
  });

  group('PIN storage', () {
    test('no PIN set initially', () async {
      expect(await repo.hasPin(), isFalse);
    });

    test('setPin stores the hashed value, then hasPin is true', () async {
      await repo.setPin('123456');
      expect(await repo.hasPin(), isTrue);
      // Plaintext PIN must never be persisted.
      expect(store.values.any((v) => v.contains('123456')), isFalse);
    });

    test('verifyPin true for correct PIN, false for wrong', () async {
      await repo.setPin('123456');
      expect(await repo.verifyPin('123456'), isTrue);
      expect(await repo.verifyPin('000000'), isFalse);
    });

    test('verifyPin false when no PIN is stored', () async {
      expect(await repo.verifyPin('123456'), isFalse);
    });

    test('clearPin removes the stored PIN', () async {
      await repo.setPin('123456');
      await repo.clearPin();
      expect(await repo.hasPin(), isFalse);
    });
  });

  group('biometrics', () {
    test('canUseBiometrics true only when supported AND enrolled', () async {
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => localAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      expect(await repo.canUseBiometrics(), isTrue);
    });

    test('canUseBiometrics false when none enrolled', () async {
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => localAuth.getAvailableBiometrics())
          .thenAnswer((_) async => <BiometricType>[]);
      expect(await repo.canUseBiometrics(), isFalse);
    });

    test('authenticateBiometric requests biometricOnly and returns result',
        () async {
      when(() => localAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);

      final ok = await repo.authenticateBiometric('unlock');

      expect(ok, isTrue);
      final captured = verify(() => localAuth.authenticate(
            localizedReason: 'unlock',
            options: captureAny(named: 'options'),
          )).captured.single as AuthenticationOptions;
      expect(captured.biometricOnly, isTrue);
    });

    test('authenticateBiometric returns false on PlatformException', () async {
      when(() => localAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenThrow(PlatformException(code: 'NotAvailable'));
      expect(await repo.authenticateBiometric('unlock'), isFalse);
    });
  });

  group('secure-storage fault tolerance (keystore invalidation)', () {
    // EncryptedSharedPreferences throws after an OS keystore reset. The lock
    // must degrade gracefully, never crash the controller into AsyncError.
    test('loadConfig survives a throwing secure read (pinSet degrades false)',
        () async {
      await repo.setEnabled(true);
      when(() => secure.read(key: any(named: 'key')))
          .thenThrow(PlatformException(code: 'keystore'));

      final config = await repo.loadConfig();

      expect(config.enabled, isTrue); // prefs flags unaffected
      expect(config.pinSet, isFalse);
    });

    test('readLockout degrades to none on a throwing secure read', () async {
      when(() => secure.read(key: any(named: 'key')))
          .thenThrow(PlatformException(code: 'keystore'));
      final lockout = await repo.readLockout();
      expect(lockout.failedAttempts, 0);
      expect(lockout.lockedUntil, isNull);
    });

    test('verifyPin returns false on a throwing secure read', () async {
      when(() => secure.read(key: any(named: 'key')))
          .thenThrow(PlatformException(code: 'keystore'));
      expect(await repo.verifyPin('123456'), isFalse);
    });

    test('readLockout degrades on malformed persisted values', () async {
      store['applock_failed_attempts'] = 'not-a-number';
      store['applock_locked_until'] = 'garbage-not-iso8601';

      final lockout = await repo.readLockout();

      expect(lockout.failedAttempts, 0);
      expect(lockout.lockedUntil, isNull);
    });
  });

  group('lockout persistence', () {
    test('default lockout is empty', () async {
      final lockout = await repo.readLockout();
      expect(lockout.failedAttempts, 0);
      expect(lockout.lockedUntil, isNull);
    });

    test('writeLockout then readLockout round-trips', () async {
      final until = DateTime.utc(2026, 6, 3, 12, 0, 0);
      await repo.writeLockout(
        LockoutState(failedAttempts: 5, lockedUntil: until),
      );
      final read = await repo.readLockout();
      expect(read.failedAttempts, 5);
      expect(read.lockedUntil, until);
    });

    test('writing an empty lockout clears persisted state', () async {
      await repo.writeLockout(
        LockoutState(failedAttempts: 5, lockedUntil: DateTime.utc(2026)),
      );
      await repo.writeLockout(LockoutState.none);
      final read = await repo.readLockout();
      expect(read.failedAttempts, 0);
      expect(read.lockedUntil, isNull);
    });
  });
}
