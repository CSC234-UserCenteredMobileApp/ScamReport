import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_gate.dart';
import 'package:mobile/features/app_lock/presentation/lock_screen.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';
import 'package:mobile/features/app_lock/presentation/widgets/app_lock_cover.dart';
import 'package:mobile/l10n/l10n.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

const _enabled = AppLockConfig(
  enabled: true,
  biometricEnabled: false,
  pinSet: true,
  backgroundTimeout: Duration(minutes: 1),
);
const _disabled = AppLockConfig(
  enabled: false,
  biometricEnabled: false,
  pinSet: false,
  backgroundTimeout: Duration(minutes: 1),
);

const _content = Key('app-content');
const _splash = Key('app-lock-splash');

Future<void> _pump(WidgetTester tester, MockAppLockRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLockRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppLockGate(
          child: Scaffold(body: Center(child: Text('APP', key: _content))),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  late MockAppLockRepository repo;

  setUp(() {
    repo = MockAppLockRepository();
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
  });

  testWidgets('shows the splash (not the lock screen) while config loads',
      (tester) async {
    when(() => repo.loadConfig())
        .thenAnswer((_) => Completer<AppLockConfig>().future);
    await _pump(tester, repo);
    await tester.pump();

    expect(find.byKey(_splash), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('covers content with the lock screen when locked',
      (tester) async {
    when(() => repo.loadConfig()).thenAnswer((_) async => _enabled);
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byType(LockScreen), findsOneWidget);
    // Content stays mounted underneath so navigation state survives unlock.
    expect(find.byKey(_content), findsOneWidget);
  });

  testWidgets('fails CLOSED (cover, not content) when the controller errors',
      (tester) async {
    // e.g. keystore invalidation -> secure storage read throws at startup.
    when(() => repo.loadConfig())
        .thenThrow(PlatformException(code: 'keystore'));
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byKey(_splash), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('renders the privacy cover when obscured (backgrounded)',
      (tester) async {
    when(() => repo.loadConfig()).thenAnswer((_) async => _disabled);
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
          home: const AppLockGate(
            child: Scaffold(body: Center(child: Text('APP', key: _content))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppLockCover), findsNothing);

    container.read(appLockObscuredProvider.notifier).state = true;
    await tester.pump();

    expect(find.byType(AppLockCover), findsOneWidget);
  });

  testWidgets('reveals content with no cover when disabled', (tester) async {
    when(() => repo.loadConfig()).thenAnswer((_) async => _disabled);
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byKey(_content), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byKey(_splash), findsNothing);
  });
}
