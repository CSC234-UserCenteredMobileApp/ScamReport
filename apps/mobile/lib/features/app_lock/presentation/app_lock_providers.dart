import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/di/cache.dart';
import '../data/app_lock_repository_impl.dart';
import '../domain/app_lock_config.dart';
import '../domain/app_lock_repository.dart';
import '../domain/app_lock_runtime.dart';

/// Wraps `local_auth` so it can be overridden in tests.
final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Async because it depends on [sharedPreferencesProvider]. Override this in
/// tests to inject a mock repository.
final appLockRepositoryProvider =
    FutureProvider<AppLockRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppLockRepositoryImpl(
    secure: ref.watch(secureStorageProvider),
    prefs: prefs,
    localAuth: ref.watch(localAuthProvider),
  );
});

final appLockControllerProvider =
    AsyncNotifierProvider<AppLockController, AppLockRuntime>(
  AppLockController.new,
);

/// True while the app is backgrounded with the lock enabled — drives the
/// privacy cover that blanks the OS app-switcher thumbnail. Set by
/// AppLockObserver.
final appLockObscuredProvider = StateProvider<bool>((ref) => false);

/// Threshold of consecutive wrong PINs before the first lockout engages.
const int _lockoutThreshold = 5;

/// First lockout duration; doubles per extra failure, capped at [_lockoutCap].
const Duration _lockoutBase = Duration(seconds: 30);
const Duration _lockoutCap = Duration(minutes: 5);

class AppLockController extends AsyncNotifier<AppLockRuntime> {
  late AppLockRepository _repo;

  // Set while a biometric prompt is in flight. The OS biometric sheet fires
  // lifecycle (inactive/paused/resumed) events; we must ignore them so the
  // prompt doesn't arm the relock timer or trigger a spurious re-lock.
  bool _authInFlight = false;

  // When the app was last backgrounded, or null if foregrounded / never armed.
  DateTime? _backgroundedAt;

  bool get authInFlight => _authInFlight;

  @override
  Future<AppLockRuntime> build() async {
    _repo = await ref.watch(appLockRepositoryProvider.future);
    final config = await _repo.loadConfig();
    final lockout = await _repo.readLockout();
    return AppLockRuntime(
      // First-frame safety: when the feature is on, start LOCKED so content
      // never flashes before the gate mounts.
      status: config.enabled ? AppLockStatus.locked : AppLockStatus.unlocked,
      config: config,
      lockout: lockout,
    );
  }

  // ---- Lifecycle (called by AppLockObserver) -------------------------------

  void onBackgrounded(DateTime now) {
    if (_authInFlight) return; // biometric sheet, not a real background
    _backgroundedAt = now;
  }

  void onResumed(DateTime now) {
    if (_authInFlight) return; // returning from the biometric sheet
    final bg = _backgroundedAt;
    _backgroundedAt = null;

    final rt = state.valueOrNull;
    if (rt == null || !rt.config.enabled) return;
    if (rt.status != AppLockStatus.unlocked) return; // already locked
    if (bg == null) return;

    if (now.difference(bg) >= rt.config.backgroundTimeout) {
      state = AsyncData(rt.copyWith(status: AppLockStatus.locked));
    }
  }

  // ---- Unlock attempts -----------------------------------------------------

  Future<UnlockOutcome> tryBiometric(String localizedReason,
      {DateTime? now}) async {
    final rt = state.valueOrNull;
    if (rt == null) return UnlockOutcome.error;
    if (!rt.config.biometricEnabled) return UnlockOutcome.biometricUnavailable;
    // Defense-in-depth: the lock screen already disables its biometric
    // affordances during a lockout, but the controller must not rely on UI
    // discipline alone.
    if (rt.lockout.isLockedAt(now ?? DateTime.now())) {
      return UnlockOutcome.lockedOut;
    }

    _authInFlight = true;
    try {
      final ok = await _repo.authenticateBiometric(localizedReason);
      if (!ok) return UnlockOutcome.biometricFailed;
      await _repo.writeLockout(LockoutState.none);
      state = AsyncData(
        state.requireValue.copyWith(
          status: AppLockStatus.unlocked,
          lockout: LockoutState.none,
        ),
      );
      return UnlockOutcome.success;
    } finally {
      _authInFlight = false;
    }
  }

  Future<UnlockOutcome> submitPin(String pin, {DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final rt = state.valueOrNull;
    if (rt == null) return UnlockOutcome.error;
    if (rt.lockout.isLockedAt(clock)) return UnlockOutcome.lockedOut;

    final ok = await _repo.verifyPin(pin);
    if (ok) {
      await _repo.writeLockout(LockoutState.none);
      state = AsyncData(
        rt.copyWith(status: AppLockStatus.unlocked, lockout: LockoutState.none),
      );
      return UnlockOutcome.success;
    }

    final attempts = rt.lockout.failedAttempts + 1;
    final lockedUntil =
        attempts >= _lockoutThreshold ? clock.add(_backoffFor(attempts)) : null;
    final lockout =
        LockoutState(failedAttempts: attempts, lockedUntil: lockedUntil);
    await _repo.writeLockout(lockout);
    state = AsyncData(rt.copyWith(lockout: lockout));
    return lockedUntil != null
        ? UnlockOutcome.lockedOut
        : UnlockOutcome.wrongPin;
  }

  // ---- Settings mutations --------------------------------------------------

  /// Turns the lock on with a freshly-set PIN. Leaves the app unlocked (the
  /// user is configuring it right now).
  Future<void> enableWithPin(String pin) async {
    await _repo.setPin(pin);
    await _repo.setEnabled(true);
    final config = (state.valueOrNull?.config ?? AppLockConfig.defaults)
        .copyWith(enabled: true, pinSet: true);
    state = AsyncData(
      AppLockRuntime(
        status: AppLockStatus.unlocked,
        config: config,
        lockout: LockoutState.none,
      ),
    );
  }

  /// Turns the lock off and wipes the PIN, biometric flag, and lockout.
  Future<void> disable() async {
    await _repo.setEnabled(false);
    await _repo.setBiometricEnabled(false);
    await _repo.clearPin();
    await _repo.writeLockout(LockoutState.none);
    state = const AsyncData(
      AppLockRuntime(
        status: AppLockStatus.unlocked,
        config: AppLockConfig.defaults,
        lockout: LockoutState.none,
      ),
    );
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _repo.setBiometricEnabled(value);
    final rt = state.valueOrNull;
    if (rt == null) return;
    state = AsyncData(
      rt.copyWith(config: rt.config.copyWith(biometricEnabled: value)),
    );
  }

  Future<void> changePin(String pin) async {
    await _repo.setPin(pin);
    final rt = state.valueOrNull;
    if (rt == null) return;
    state = AsyncData(rt.copyWith(config: rt.config.copyWith(pinSet: true)));
  }

  /// Verifies a PIN without mutating lock state — used by settings re-auth.
  Future<bool> verifyPinValue(String pin) => _repo.verifyPin(pin);

  Future<bool> canUseBiometrics() => _repo.canUseBiometrics();

  Duration _backoffFor(int attempts) {
    final over = attempts - _lockoutThreshold; // 0 at the threshold
    final seconds = _lockoutBase.inSeconds * (1 << over);
    return Duration(
      seconds: seconds.clamp(0, _lockoutCap.inSeconds),
    );
  }
}
