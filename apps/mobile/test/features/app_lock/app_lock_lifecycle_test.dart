import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_lifecycle.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

const _enabled = AppLockConfig(
  enabled: true,
  biometricEnabled: true,
  pinSet: true,
  backgroundTimeout: Duration(minutes: 1),
);

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  late MockAppLockRepository repo;

  setUp(() {
    repo = MockAppLockRepository();
    when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
    when(() => repo.writeLockout(any())).thenAnswer((_) async {});
  });

  Future<(ProviderContainer, AppLockController)> setup() async {
    final c = ProviderContainer(
      overrides: [appLockRepositoryProvider.overrideWith((ref) async => repo)],
    );
    addTearDown(c.dispose);
    await c.read(appLockControllerProvider.future);
    return (c, c.read(appLockControllerProvider.notifier));
  }

  test('pausing sets the privacy cover; resuming clears it', () async {
    final (_, controller) = await setup();
    bool? obscured;
    void setObscured(bool v) => obscured = v;
    final now = DateTime.utc(2026, 6, 3, 10);

    handleLifecycle(AppLifecycleState.paused, controller,
        enabled: true, setObscured: setObscured, now: now);
    expect(obscured, isTrue);

    handleLifecycle(AppLifecycleState.resumed, controller,
        enabled: true, setObscured: setObscured,
        now: now.add(const Duration(seconds: 5)));
    expect(obscured, isFalse);
  });

  test('does NOT set the privacy cover while biometric auth is in flight',
      () async {
    final (_, controller) = await setup();
    when(() => repo.authenticateBiometric(any()))
        .thenAnswer((_) => Completer<bool>().future); // stays pending
    // ignore: unawaited_futures
    controller.tryBiometric('reason'); // authInFlight = true

    bool? obscured;
    handleLifecycle(AppLifecycleState.inactive, controller,
        enabled: true, setObscured: (v) => obscured = v,
        now: DateTime.utc(2026, 6, 3, 10));

    expect(obscured, isNull); // suppressed
  });
}
