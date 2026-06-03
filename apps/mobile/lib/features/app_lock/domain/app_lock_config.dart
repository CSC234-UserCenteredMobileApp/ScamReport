/// Persisted app-lock configuration. Source of truth lives across
/// SharedPreferences (the flags + timeout) and secure storage (whether a PIN
/// hash exists → [pinSet]). Pure Dart, no Flutter imports.
class AppLockConfig {
  const AppLockConfig({
    required this.enabled,
    required this.biometricEnabled,
    required this.pinSet,
    required this.backgroundTimeout,
  });

  /// Master switch — the lock only engages when this is true.
  final bool enabled;

  /// Whether biometric unlock is offered in addition to the PIN.
  final bool biometricEnabled;

  /// Whether a PIN has been set. A PIN is mandatory whenever [enabled] is true
  /// (it is the guaranteed fallback), so the two are set together.
  final bool pinSet;

  /// Grace period after backgrounding before the app re-locks on resume.
  final Duration backgroundTimeout;

  static const AppLockConfig defaults = AppLockConfig(
    enabled: false,
    biometricEnabled: false,
    pinSet: false,
    backgroundTimeout: Duration(minutes: 1),
  );

  AppLockConfig copyWith({
    bool? enabled,
    bool? biometricEnabled,
    bool? pinSet,
    Duration? backgroundTimeout,
  }) {
    return AppLockConfig(
      enabled: enabled ?? this.enabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinSet: pinSet ?? this.pinSet,
      backgroundTimeout: backgroundTimeout ?? this.backgroundTimeout,
    );
  }
}

/// Brute-force protection state. Persisted so killing the app cannot reset it.
class LockoutState {
  const LockoutState({
    required this.failedAttempts,
    required this.lockedUntil,
  });

  /// Consecutive wrong PIN entries since the last successful unlock.
  final int failedAttempts;

  /// When the current lockout expires, or null if not locked out.
  final DateTime? lockedUntil;

  static const LockoutState none =
      LockoutState(failedAttempts: 0, lockedUntil: null);

  /// True when [now] falls before [lockedUntil].
  bool isLockedAt(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  /// Remaining lockout duration at [now] (zero when not locked out).
  Duration remainingAt(DateTime now) {
    if (!isLockedAt(now)) return Duration.zero;
    return lockedUntil!.difference(now);
  }

  LockoutState copyWith({int? failedAttempts, DateTime? lockedUntil}) {
    return LockoutState(
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
}
