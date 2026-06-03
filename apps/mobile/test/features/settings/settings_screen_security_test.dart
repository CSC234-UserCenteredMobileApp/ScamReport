// Security section (biometric/PIN app lock) behavior in Settings:
//  - disabling the lock requires PIN re-auth (dismiss => stays enabled)
//  - biometric toggle refuses when no biometric is enrolled
//  - section stays reachable when the lock is ON but the flag was turned off
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';
import 'package:mobile/features/app_lock/presentation/pin_verify_sheet.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_state.dart';
import 'package:mobile/features/settings/presentation/settings_providers.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<SettingsState> build() async => SettingsState.defaults;

  @override
  Future<void> save(SettingsState next) async {
    state = AsyncValue.data(next);
  }
}

const _lockOn = AppLockConfig(
  enabled: true,
  biometricEnabled: false,
  pinSet: true,
  backgroundTimeout: Duration(minutes: 1),
);

Widget _wrap(Widget widget) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    );

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  late MockAppLockRepository repo;

  setUp(() {
    repo = MockAppLockRepository();
    when(() => repo.loadConfig()).thenAnswer((_) async => _lockOn);
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
    when(() => repo.writeLockout(any())).thenAnswer((_) async {});
    when(() => repo.setEnabled(any())).thenAnswer((_) async {});
    when(() => repo.setBiometricEnabled(any())).thenAnswer((_) async {});
    when(() => repo.clearPin()).thenAnswer((_) async {});
  });

  Future<void> pumpSettings(WidgetTester tester, {required bool flag}) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) async => null),
          settingsProvider.overrideWith(_FakeSettingsNotifier.new),
          settingsRepositoryProvider
              .overrideWithValue(SettingsRepository(prefs)),
          featureFlagProvider('enable_sms_scan').overrideWith((_) => false),
          featureFlagProvider('enable_call_screening')
              .overrideWith((_) => false),
          featureFlagProvider('enable_biometric_login')
              .overrideWith((_) => flag),
          appLockRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: _wrap(const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.byKey(ValueKey('pinpad-$d')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('section stays visible when lock is ON but the flag is OFF',
      (tester) async {
    await pumpSettings(tester, flag: false);
    expect(find.text('App Lock'), findsOneWidget);
  });

  testWidgets('dismissing the re-auth sheet does NOT disable the lock',
      (tester) async {
    await pumpSettings(tester, flag: true);

    await tester.tap(find.text('App Lock'));
    await tester.pumpAndSettle();
    expect(find.byType(PinVerifyView), findsOneWidget);

    // Dismiss via the modal barrier (above the sheet).
    await tester.tapAt(const Offset(400, 20));
    await tester.pumpAndSettle();

    expect(find.byType(PinVerifyView), findsNothing);
    verifyNever(() => repo.setEnabled(false));
    verifyNever(() => repo.clearPin());
  });

  testWidgets('verifying the PIN disables the lock and wipes the PIN',
      (tester) async {
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    await pumpSettings(tester, flag: true);

    await tester.tap(find.text('App Lock'));
    await tester.pumpAndSettle();
    await enterPin(tester, '123456');

    verify(() => repo.setEnabled(false)).called(1);
    verify(() => repo.clearPin()).called(1);
  });

  testWidgets('biometric toggle refuses when no biometric is enrolled',
      (tester) async {
    when(() => repo.canUseBiometrics()).thenAnswer((_) async => false);
    await pumpSettings(tester, flag: true);

    await tester.tap(find.text('Use biometric unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Biometric unavailable — use your PIN'), findsOneWidget);
    verifyNever(() => repo.setBiometricEnabled(true));
  });

  testWidgets('biometric toggle persists when biometric is available',
      (tester) async {
    when(() => repo.canUseBiometrics()).thenAnswer((_) async => true);
    await pumpSettings(tester, flag: true);

    await tester.tap(find.text('Use biometric unlock'));
    await tester.pumpAndSettle();

    verify(() => repo.setBiometricEnabled(true)).called(1);
  });
}
