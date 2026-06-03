import 'app_lock_config.dart';

/// Runtime lock state, distinct from the persisted [AppLockConfig].
enum AppLockStatus {
  /// The gate must hide app content and present the unlock UI.
  locked,

  /// App content is visible.
  unlocked,
}

/// Result of an unlock attempt, mapped to a localized message by the UI.
enum UnlockOutcome {
  success,
  wrongPin,
  lockedOut,
  biometricFailed,
  biometricUnavailable,
  error,
}

/// The controller's full runtime state.
class AppLockRuntime {
  const AppLockRuntime({
    required this.status,
    required this.config,
    required this.lockout,
  });

  final AppLockStatus status;
  final AppLockConfig config;
  final LockoutState lockout;

  bool get isUnlocked => status == AppLockStatus.unlocked;

  AppLockRuntime copyWith({
    AppLockStatus? status,
    AppLockConfig? config,
    LockoutState? lockout,
  }) {
    return AppLockRuntime(
      status: status ?? this.status,
      config: config ?? this.config,
      lockout: lockout ?? this.lockout,
    );
  }
}
