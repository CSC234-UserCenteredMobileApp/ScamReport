import 'app_lock_config.dart';

/// Device-facing operations behind the app lock: persisted config, PIN storage
/// (hashed), biometric prompts, and lockout state. Pure interface so the
/// controller can be tested against a mock.
abstract class AppLockRepository {
  Future<AppLockConfig> loadConfig();
  Future<void> setEnabled(bool enabled);
  Future<void> setBiometricEnabled(bool enabled);

  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();

  /// True only when the device supports biometrics AND at least one is
  /// enrolled.
  Future<bool> canUseBiometrics();

  /// Prompts for biometric auth (biometric-only — never the device PIN).
  /// Returns false on cancel/failure/unavailable rather than throwing.
  Future<bool> authenticateBiometric(String localizedReason);

  Future<LockoutState> readLockout();
  Future<void> writeLockout(LockoutState state);
}
