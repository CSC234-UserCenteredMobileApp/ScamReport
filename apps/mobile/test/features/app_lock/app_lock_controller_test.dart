import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/domain/app_lock_runtime.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

const _enabled = AppLockConfig(
  enabled: true,
  biometricEnabled: true,
  pinSet: true,
  backgroundTimeout: Duration(minutes: 1),
);
const _disabled = AppLockConfig(
  enabled: false,
  biometricEnabled: false,
  pinSet: false,
  backgroundTimeout: Duration(minutes: 1),
);

ProviderContainer _containerFor(MockAppLockRepository repo) {
  final container = ProviderContainer(
    overrides: [
      appLockRepositoryProvider.overrideWith((ref) async => repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AppLockRuntime> _build(ProviderContainer c) =>
    c.read(appLockControllerProvider.future);

AppLockController _ctrl(ProviderContainer c) =>
    c.read(appLockControllerProvider.notifier);

AppLockRuntime _state(ProviderContainer c) =>
    c.read(appLockControllerProvider).requireValue;

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  late MockAppLockRepository repo;

  setUp(() {
    repo = MockAppLockRepository();
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
    when(() => repo.writeLockout(any())).thenAnswer((_) async {});
  });

  group('initial state (no first-frame flash)', () {
    test('enabled config builds to LOCKED', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      final c = _containerFor(repo);
      final rt = await _build(c);
      expect(rt.status, AppLockStatus.locked);
    });

    test('disabled config builds to UNLOCKED', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _disabled);
      final c = _containerFor(repo);
      final rt = await _build(c);
      expect(rt.status, AppLockStatus.unlocked);
    });

    test('state is AsyncLoading before the config resolves', () {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      final c = _containerFor(repo);
      // Read synchronously, before awaiting build.
      expect(c.read(appLockControllerProvider).isLoading, isTrue);
    });
  });

  group('background timeout threshold', () {
    Future<ProviderContainer> unlockedContainer() async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      when(() => repo.authenticateBiometric(any()))
          .thenAnswer((_) async => true);
      final c = _containerFor(repo);
      await _build(c);
      // Unlock via biometric so we start from a genuine unlocked state.
      await _ctrl(c).tryBiometric('reason');
      expect(_state(c).status, AppLockStatus.unlocked);
      return c;
    }

    test('resume BEFORE timeout does NOT relock', () async {
      final c = await unlockedContainer();
      final t0 = DateTime.utc(2026, 6, 3, 10, 0, 0);
      _ctrl(c).onBackgrounded(t0);
      _ctrl(c).onResumed(t0.add(const Duration(seconds: 30)));
      expect(_state(c).status, AppLockStatus.unlocked);
    });

    test('resume AFTER timeout relocks', () async {
      final c = await unlockedContainer();
      final t0 = DateTime.utc(2026, 6, 3, 10, 0, 0);
      _ctrl(c).onBackgrounded(t0);
      _ctrl(c).onResumed(t0.add(const Duration(seconds: 90)));
      expect(_state(c).status, AppLockStatus.locked);
    });

    test('disabled config never relocks on resume', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _disabled);
      final c = _containerFor(repo);
      await _build(c);
      final t0 = DateTime.utc(2026, 6, 3, 10, 0, 0);
      _ctrl(c).onBackgrounded(t0);
      _ctrl(c).onResumed(t0.add(const Duration(hours: 1)));
      expect(_state(c).status, AppLockStatus.unlocked);
    });
  });

  test('auth-in-flight suppresses the background timer (no spurious relock)',
      () async {
    when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
    // Biometric stays pending until we complete it — auth is "in flight".
    final gate = Completer<bool>();
    when(() => repo.authenticateBiometric(any()))
        .thenAnswer((_) => gate.future);

    final c = _containerFor(repo);
    await _build(c);

    final pending = _ctrl(c).tryBiometric('reason'); // do not await yet
    // The biometric sheet itself fires lifecycle events; they must be ignored.
    final t0 = DateTime.utc(2026, 6, 3, 10, 0, 0);
    _ctrl(c).onBackgrounded(t0);

    gate.complete(true);
    await pending;
    expect(_state(c).status, AppLockStatus.unlocked);

    // Long after auth, a resume must not relock — the pause during auth never
    // armed the timer.
    _ctrl(c).onResumed(t0.add(const Duration(minutes: 5)));
    expect(_state(c).status, AppLockStatus.unlocked);
  });

  group('PIN verification + lockout backoff', () {
    Future<ProviderContainer> lockedContainer() async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      final c = _containerFor(repo);
      await _build(c);
      return c;
    }

    test('correct PIN unlocks and resets lockout', () async {
      when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
      final c = await lockedContainer();
      final outcome =
          await _ctrl(c).submitPin('123456', now: DateTime.utc(2026));
      expect(outcome, UnlockOutcome.success);
      expect(_state(c).status, AppLockStatus.unlocked);
      verify(() => repo.writeLockout(LockoutState.none)).called(1);
    });

    test('wrong PIN returns wrongPin and increments attempts', () async {
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      final c = await lockedContainer();
      final outcome =
          await _ctrl(c).submitPin('000000', now: DateTime.utc(2026));
      expect(outcome, UnlockOutcome.wrongPin);
      expect(_state(c).lockout.failedAttempts, 1);
      expect(_state(c).status, AppLockStatus.locked);
    });

    test('5th wrong PIN triggers a 30s lockout', () async {
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      final c = await lockedContainer();
      final now = DateTime.utc(2026, 6, 3, 10, 0, 0);
      UnlockOutcome? last;
      for (var i = 0; i < 5; i++) {
        last = await _ctrl(c).submitPin('000000', now: now);
      }
      expect(last, UnlockOutcome.lockedOut);
      final lockout = _state(c).lockout;
      expect(lockout.failedAttempts, 5);
      expect(lockout.lockedUntil, now.add(const Duration(seconds: 30)));
    });

    test('6th failure doubles the lockout to 60s', () async {
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      final c = await lockedContainer();
      final now = DateTime.utc(2026, 6, 3, 10, 0, 0);
      for (var i = 0; i < 5; i++) {
        await _ctrl(c).submitPin('000000', now: now);
      }
      // After the 30s lockout elapses, one more wrong try.
      final later = now.add(const Duration(seconds: 31));
      await _ctrl(c).submitPin('000000', now: later);
      expect(_state(c).lockout.lockedUntil,
          later.add(const Duration(seconds: 60)));
    });

    test('backoff caps at 5 minutes from attempt 9 onward', () async {
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      final c = await lockedContainer();
      var now = DateTime.utc(2026, 6, 3, 10, 0, 0);
      for (var attempt = 1; attempt <= 10; attempt++) {
        await _ctrl(c).submitPin('000000', now: now);
        final lockout = _state(c).lockout;
        expect(lockout.failedAttempts, attempt);
        if (attempt >= 9) {
          expect(
            lockout.lockedUntil,
            now.add(const Duration(minutes: 5)),
            reason: 'attempt $attempt must clamp at the 5-minute cap',
          );
        }
        // Advance the clock past any active lockout before the next try.
        if (lockout.lockedUntil != null) {
          now = lockout.lockedUntil!.add(const Duration(seconds: 1));
        }
      }
    });

    test('boots into an active persisted lockout (kill does not reset it)',
        () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      final until = DateTime.utc(2026, 6, 3, 12, 0, 0);
      when(() => repo.readLockout()).thenAnswer(
        (_) async => LockoutState(failedAttempts: 5, lockedUntil: until),
      );
      final c = _containerFor(repo);
      final rt = await _build(c);

      expect(rt.lockout.isLockedAt(DateTime.utc(2026, 6, 3, 11, 59)), isTrue);
      final outcome = await _ctrl(c)
          .submitPin('123456', now: DateTime.utc(2026, 6, 3, 11, 59));
      expect(outcome, UnlockOutcome.lockedOut);
      verifyNever(() => repo.verifyPin(any()));
    });

    test(
        'submitPin during an active lockout returns lockedOut without verifying',
        () async {
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      final c = await lockedContainer();
      final now = DateTime.utc(2026, 6, 3, 10, 0, 0);
      for (var i = 0; i < 5; i++) {
        await _ctrl(c).submitPin('000000', now: now);
      }
      clearInteractions(repo);
      // Within the lockout window.
      final outcome = await _ctrl(c)
          .submitPin('123456', now: now.add(const Duration(seconds: 5)));
      expect(outcome, UnlockOutcome.lockedOut);
      verifyNever(() => repo.verifyPin(any()));
    });
  });

  group('config mutations (settings)', () {
    test('enableWithPin stores PIN, enables, and unlocks', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _disabled);
      when(() => repo.setPin(any())).thenAnswer((_) async {});
      when(() => repo.setEnabled(any())).thenAnswer((_) async {});
      final c = _containerFor(repo);
      await _build(c);

      await _ctrl(c).enableWithPin('123456');

      final rt = _state(c);
      expect(rt.config.enabled, isTrue);
      expect(rt.config.pinSet, isTrue);
      expect(rt.status, AppLockStatus.unlocked);
      verify(() => repo.setPin('123456')).called(1);
      verify(() => repo.setEnabled(true)).called(1);
    });

    test('disable clears the PIN, flags, and lockout', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      when(() => repo.setEnabled(any())).thenAnswer((_) async {});
      when(() => repo.setBiometricEnabled(any())).thenAnswer((_) async {});
      when(() => repo.clearPin()).thenAnswer((_) async {});
      final c = _containerFor(repo);
      await _build(c);

      await _ctrl(c).disable();

      final rt = _state(c);
      expect(rt.config.enabled, isFalse);
      expect(rt.config.pinSet, isFalse);
      expect(rt.config.biometricEnabled, isFalse);
      verify(() => repo.clearPin()).called(1);
      verify(() => repo.setEnabled(false)).called(1);
    });

    test('setBiometricEnabled updates config + persists', () async {
      when(() => repo.loadConfig())
          .thenAnswer((_) async => _enabled.copyWith(biometricEnabled: false));
      when(() => repo.setBiometricEnabled(any())).thenAnswer((_) async {});
      final c = _containerFor(repo);
      await _build(c);

      await _ctrl(c).setBiometricEnabled(true);

      expect(_state(c).config.biometricEnabled, isTrue);
      verify(() => repo.setBiometricEnabled(true)).called(1);
    });

    test('verifyPinValue delegates to repo without changing lock state',
        () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
      final c = _containerFor(repo);
      await _build(c);

      expect(await _ctrl(c).verifyPinValue('123456'), isTrue);
      expect(_state(c).status, AppLockStatus.locked); // unchanged
    });
  });

  group('biometric unlock', () {
    test('success unlocks', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      when(() => repo.authenticateBiometric(any()))
          .thenAnswer((_) async => true);
      final c = _containerFor(repo);
      await _build(c);
      final outcome = await _ctrl(c).tryBiometric('reason');
      expect(outcome, UnlockOutcome.success);
      expect(_state(c).status, AppLockStatus.unlocked);
    });

    test('failure stays locked', () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      when(() => repo.authenticateBiometric(any()))
          .thenAnswer((_) async => false);
      final c = _containerFor(repo);
      await _build(c);
      final outcome = await _ctrl(c).tryBiometric('reason');
      expect(outcome, UnlockOutcome.biometricFailed);
      expect(_state(c).status, AppLockStatus.locked);
    });

    test('refuses to prompt during an active lockout (defense-in-depth)',
        () async {
      when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
      when(() => repo.readLockout()).thenAnswer(
        (_) async => LockoutState(
          failedAttempts: 5,
          lockedUntil: DateTime.utc(2026, 6, 3, 12),
        ),
      );
      final c = _containerFor(repo);
      await _build(c);

      final outcome = await _ctrl(c)
          .tryBiometric('reason', now: DateTime.utc(2026, 6, 3, 11, 59));
      expect(outcome, UnlockOutcome.lockedOut);
      verifyNever(() => repo.authenticateBiometric(any()));
    });

    test('returns biometricUnavailable (no prompt) when biometric is off',
        () async {
      when(() => repo.loadConfig())
          .thenAnswer((_) async => _enabled.copyWith(biometricEnabled: false));
      final c = _containerFor(repo);
      await _build(c);

      expect(
        await _ctrl(c).tryBiometric('reason'),
        UnlockOutcome.biometricUnavailable,
      );
      verifyNever(() => repo.authenticateBiometric(any()));
    });
  });
}
