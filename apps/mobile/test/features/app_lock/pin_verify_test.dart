import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';
import 'package:mobile/features/app_lock/presentation/pin_verify_sheet.dart';
import 'package:mobile/l10n/l10n.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

const _enabled = AppLockConfig(
  enabled: true,
  biometricEnabled: false,
  pinSet: true,
  backgroundTimeout: Duration(minutes: 1),
);

Future<void> _enter(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(ValueKey('pinpad-$d')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  late MockAppLockRepository repo;

  setUp(() {
    repo = MockAppLockRepository();
    when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
  });

  testWidgets('correct PIN triggers onVerified', (tester) async {
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    var verified = false;
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
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PinVerifyView(onVerified: () => verified = true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _enter(tester, '123456');
    expect(verified, isTrue);
  });

  testWidgets('wrong PIN shows error and does not verify', (tester) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    var verified = false;
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
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PinVerifyView(onVerified: () => verified = true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _enter(tester, '000000');
    expect(verified, isFalse);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PinVerifyView)),
    )!;
    expect(find.text(l10n.appLockWrongPin), findsOneWidget);
  });
}
