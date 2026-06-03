import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/domain/app_lock_runtime.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';
import 'package:mobile/features/app_lock/presentation/lock_screen.dart';
import 'package:mobile/features/app_lock/presentation/widgets/pin_dots.dart';
import 'package:mobile/l10n/l10n.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

// PIN-only config (biometric off) so the auto-biometric path doesn't interfere.
const _pinOnly = AppLockConfig(
  enabled: true,
  biometricEnabled: false,
  pinSet: true,
  backgroundTimeout: Duration(minutes: 1),
);

Widget _app(Widget child) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  MockAppLockRepository repo,
) async {
  final container = ProviderContainer(
    overrides: [
      appLockRepositoryProvider.overrideWith((ref) async => repo),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appLockControllerProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _app(const LockScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _enter(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(ValueKey('pinpad-$d')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

AppLockStatus _status(ProviderContainer c) =>
    c.read(appLockControllerProvider).requireValue.status;

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  late MockAppLockRepository repo;

  setUp(() {
    repo = MockAppLockRepository();
    when(() => repo.loadConfig()).thenAnswer((_) async => _pinOnly);
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
    when(() => repo.writeLockout(any())).thenAnswer((_) async {});
  });

  testWidgets('entering the correct PIN unlocks', (tester) async {
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    final c = await _pump(tester, repo);
    expect(_status(c), AppLockStatus.locked);

    await _enter(tester, '123456');

    expect(_status(c), AppLockStatus.unlocked);
  });

  testWidgets('entering a wrong PIN shows an error and stays locked',
      (tester) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    final c = await _pump(tester, repo);

    await _enter(tester, '000000');

    expect(find.text(tester.l10n.appLockWrongPin), findsOneWidget);
    expect(_status(c), AppLockStatus.locked);
  });

  testWidgets('five wrong PINs locks the user out', (tester) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    await _pump(tester, repo);

    for (var i = 0; i < 5; i++) {
      await _enter(tester, '000000');
    }

    expect(find.textContaining('Try again'), findsOneWidget);
  });

  testWidgets('backspace removes the last digit, then a corrected entry unlocks',
      (tester) async {
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    final c = await _pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('pinpad-1')));
    await tester.tap(find.byKey(const ValueKey('pinpad-9')));
    await tester.pump();
    expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 2);

    await tester.tap(find.byKey(const ValueKey('pinpad-back')));
    await tester.pump();
    expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 1);

    await _enter(tester, '23456'); // completes "123456"
    expect(_status(c), AppLockStatus.unlocked);
  });

  testWidgets('boots straight into a persisted lockout with the countdown',
      (tester) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    when(() => repo.readLockout()).thenAnswer(
      (_) async => LockoutState(
        failedAttempts: 5,
        lockedUntil: DateTime.now().add(const Duration(seconds: 1)),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        appLockRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appLockControllerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(const LockScreen()),
      ),
    );
    await tester.pump(); // first frame
    await tester.pump(); // post-frame callback (ticker start)

    expect(find.textContaining('Try again'), findsOneWidget);

    // Tapping digits while locked out must not register.
    await tester.tap(find.byKey(const ValueKey('pinpad-1')));
    await tester.pump();
    expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 0);

    // Once the lockout expires the countdown disappears and entry re-enables.
    // The countdown compares against the real wall clock, so wait real time
    // (runAsync) before pumping the ticker forward.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(seconds: 2)); // ticker fires + cancels
    await tester.pumpAndSettle();
    expect(find.textContaining('Try again'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pinpad-1')));
    await tester.pump();
    expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('auto-prompts biometric on mount when enabled', (tester) async {
    when(() => repo.loadConfig()).thenAnswer(
      (_) async => _pinOnly.copyWith(biometricEnabled: true),
    );
    when(() => repo.authenticateBiometric(any()))
        .thenAnswer((_) async => true);

    final c = await _pump(tester, repo);

    verify(() => repo.authenticateBiometric(any())).called(1);
    expect(_status(c), AppLockStatus.unlocked);
  });
}

extension on WidgetTester {
  AppLocalizations get l10n =>
      AppLocalizations.of(element(find.byType(LockScreen)))!;
}
