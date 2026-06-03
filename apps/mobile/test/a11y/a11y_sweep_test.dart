// Accessibility sweep (WCAG 2.2 AA-aligned, rubric R5):
//   - androidTapTargetGuideline   — actionable targets >= 48x48 dp
//   - labeledTapTargetGuideline   — every tappable exposes a semantic label
//   - textContrastGuideline       — rendered text meets >= 4.5:1 contrast
//   - dynamic type                — screens render at textScale 2.0 without
//                                   overflow exceptions
// Covered screens: check-input, login, lock, settings, home.
// Companion doc: docs/accessibility-checklist.md
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';
import 'package:mobile/features/app_lock/presentation/lock_screen.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/check/presentation/check_input_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
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

http.Client _homeHappyClient() {
  return MockClient((request) async {
    if (request.url.path == '/stats') {
      return http.Response(
        jsonEncode({
          'data': {
            'verifiedTotal': 2184,
            'newThisWeek': 36,
            'topScamTypeLabelEn': 'SMS phishing',
            'topScamTypeLabelTh': 'SMS phishing',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(jsonEncode({'items': []}), 200,
        headers: {'content-type': 'application/json'});
  });
}

/// One sweep target: a screen plus the overrides it needs to render.
class _ScreenCase {
  const _ScreenCase(this.name, this.build);

  final String name;
  final Future<(Widget, List<Override>)> Function() build;
}

final _cases = <_ScreenCase>[
  _ScreenCase('CheckInputScreen', () async {
    return (const CheckInputScreen(), const <Override>[]);
  }),
  _ScreenCase('LoginScreen', () async {
    return (const LoginScreen(), const <Override>[]);
  }),
  _ScreenCase('LockScreen', () async {
    final repo = MockAppLockRepository();
    when(() => repo.loadConfig()).thenAnswer(
      (_) async => const AppLockConfig(
        enabled: true,
        biometricEnabled: false,
        pinSet: true,
        backgroundTimeout: Duration(minutes: 1),
      ),
    );
    when(() => repo.readLockout()).thenAnswer((_) async => LockoutState.none);
    return (
      const LockScreen(),
      [appLockRepositoryProvider.overrideWith((ref) async => repo)],
    );
  }),
  _ScreenCase('SettingsScreen', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appLockRepo = MockAppLockRepository();
    when(() => appLockRepo.loadConfig())
        .thenAnswer((_) async => AppLockConfig.defaults);
    when(() => appLockRepo.readLockout())
        .thenAnswer((_) async => LockoutState.none);
    return (
      const SettingsScreen(),
      [
        currentUserProvider.overrideWith((ref) async => null),
        settingsProvider.overrideWith(_FakeSettingsNotifier.new),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
        featureFlagProvider('enable_sms_scan').overrideWith((_) => false),
        featureFlagProvider('enable_call_screening').overrideWith((_) => false),
        featureFlagProvider('enable_biometric_login').overrideWith((_) => true),
        appLockRepositoryProvider.overrideWith((ref) async => appLockRepo),
      ],
    );
  }),
  _ScreenCase('HomeScreen', () async {
    return (
      const HomeScreen(),
      [
        httpClientProvider.overrideWithValue(_homeHappyClient()),
        currentUserProvider.overrideWith((ref) async => null),
      ],
    );
  }),
];

Widget _app(Widget screen, {double textScale = 1.0}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      // Stub destinations so taps/links resolve without the real app graph.
      for (final p in [
        '/register',
        '/forgot-password',
        '/login',
        '/verdict',
        '/check-input',
        '/search',
        '/my-reports',
        '/notifications',
      ])
        GoRoute(path: p, builder: (_, __) => const Scaffold(body: SizedBox())),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    theme: lightTheme(useGoogleFonts: false),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child ?? const SizedBox(),
    ),
  );
}

void _pinViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// GoogleFonts throws async when runtime fetching is disabled (see
/// flutter_test_config.dart) and the font isn't bundled. That's environment
/// noise, not an accessibility violation — drain those exceptions, fail on
/// anything else.

void main() {
  setUpAll(() => registerFallbackValue(LockoutState.none));

  for (final screenCase in _cases) {
    group(screenCase.name, () {
      testWidgets('meets tap-target, label, and contrast guidelines',
          (tester) async {
        _pinViewport(tester);
        final (screen, overrides) = await screenCase.build();
        await tester.pumpWidget(
          ProviderScope(overrides: overrides, child: _app(screen)),
        );
        await tester.pumpAndSettle();

        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('renders at textScale 2.0 (dynamic type)', (tester) async {
        _pinViewport(tester);
        final (screen, overrides) = await screenCase.build();
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: _app(screen, textScale: 2.0),
          ),
        );
        await tester.pumpAndSettle();
        // Overflow throws and fails the test; reaching here means it rendered.
        expect(tester.takeException(), isNull);
      });
    });
  }
}
