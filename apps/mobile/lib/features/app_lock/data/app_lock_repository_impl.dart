import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_lock_config.dart';
import '../domain/app_lock_repository.dart';
import 'pin_hasher.dart';

// Preference keys (non-sensitive flags).
const _kEnabled = 'applock_enabled';
const _kBiometric = 'applock_biometric_enabled';
const _kTimeoutSeconds = 'applock_timeout_seconds';

// Secure-storage keys (sensitive / tamper-resistant).
const _kPinHash = 'applock_pin_hash';
const _kFailedAttempts = 'applock_failed_attempts';
const _kLockedUntil = 'applock_locked_until';

const _defaultTimeoutSeconds = 60;

class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl({
    required FlutterSecureStorage secure,
    required SharedPreferences prefs,
    required LocalAuthentication localAuth,
    PinHasher hasher = const Pbkdf2PinHasher(),
  })  : _secure = secure,
        _prefs = prefs,
        _localAuth = localAuth,
        _hasher = hasher;

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth;
  final PinHasher _hasher;

  @override
  Future<AppLockConfig> loadConfig() async {
    return AppLockConfig(
      enabled: _prefs.getBool(_kEnabled) ?? false,
      biometricEnabled: _prefs.getBool(_kBiometric) ?? false,
      pinSet: await hasPin(),
      backgroundTimeout: Duration(
        seconds: _prefs.getInt(_kTimeoutSeconds) ?? _defaultTimeoutSeconds,
      ),
    );
  }

  @override
  Future<void> setEnabled(bool enabled) => _prefs.setBool(_kEnabled, enabled);

  @override
  Future<void> setBiometricEnabled(bool enabled) =>
      _prefs.setBool(_kBiometric, enabled);

  /// Secure-storage read that degrades to null instead of throwing.
  /// EncryptedSharedPreferences throws PlatformException after an OS keystore
  /// reset; if that propagated out of loadConfig()/readLockout() the lock
  /// controller would land in AsyncError and the gate would have nothing to
  /// enforce. Failing soft here keeps the lock running off the prefs flags.
  Future<String?> _safeRead(String key) async {
    try {
      return await _secure.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> hasPin() async => (await _safeRead(_kPinHash)) != null;

  @override
  Future<void> setPin(String pin) async {
    final encoded = await _hasher.hash(pin);
    await _secure.write(key: _kPinHash, value: encoded);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final stored = await _safeRead(_kPinHash);
    if (stored == null) return false;
    return _hasher.verify(pin, stored);
  }

  @override
  Future<void> clearPin() => _secure.delete(key: _kPinHash);

  @override
  Future<bool> canUseBiometrics() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticateBiometric(String localizedReason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<LockoutState> readLockout() async {
    final failed = int.tryParse(await _safeRead(_kFailedAttempts) ?? '');
    final untilRaw = await _safeRead(_kLockedUntil);
    return LockoutState(
      failedAttempts: failed ?? 0,
      lockedUntil: untilRaw == null ? null : DateTime.tryParse(untilRaw),
    );
  }

  @override
  Future<void> writeLockout(LockoutState state) async {
    if (state.failedAttempts == 0 && state.lockedUntil == null) {
      await _secure.delete(key: _kFailedAttempts);
      await _secure.delete(key: _kLockedUntil);
      return;
    }
    await _secure.write(
      key: _kFailedAttempts,
      value: state.failedAttempts.toString(),
    );
    if (state.lockedUntil != null) {
      await _secure.write(
        key: _kLockedUntil,
        value: state.lockedUntil!.toIso8601String(),
      );
    } else {
      await _secure.delete(key: _kLockedUntil);
    }
  }
}
