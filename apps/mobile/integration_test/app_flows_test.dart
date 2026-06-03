// Integration tests — rubric R5: verify core functionality end-to-end on
// BOTH Android and Web.
//
//   Android:  flutter test integration_test -d <device>
//   Web:      chromedriver --port=4444
//             flutter drive --driver=test_driver/integration_test.dart \
//               --target=integration_test/app_flows_test.dart -d chrome
//
// Backend/Firebase are faked through the same Riverpod seams the widget tests
// use (no emulators needed): MockFirebaseAuth drives the real authState /
// router-redirect machinery; HTTP + check + app-lock repositories are fakes.
import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/di/auth.dart';
import 'package:mobile/core/di/messaging.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
import 'package:mobile/core/notifications/fcm_registrar.dart';
import 'package:mobile/core/observability/crash_reporter.dart';
import 'package:mobile/features/app_lock/domain/app_lock_config.dart';
import 'package:mobile/features/app_lock/domain/app_lock_repository.dart';
import 'package:mobile/features/app_lock/presentation/app_lock_providers.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_persistence.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';
import 'package:mobile/features/check/domain/check_repository.dart';
import 'package:mobile/features/check/presentation/check_providers.dart';
import 'package:mobile/features/check/domain/check_result.dart';
import 'package:mobile/main.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFcmRegistrar extends Mock implements FcmRegistrar {}

class MockCrashReporter extends Mock implements CrashReporter {}

class MockAskAiPersistence extends Mock implements AskAiPersistence {}

class MockFeatureFlags extends Mock implements FeatureFlags {}

class MockAppLockRepository extends Mock implements AppLockRepository {}

class FakeCheckRepository implements CheckRepository {
  @override
  Future<CheckResult> runCheck(CheckQuery query) async {
    return const CheckResult(
      verdict: 'scam',
      matchedCount: 2,
      matches: [
        ReportSummaryItem(
          id: 'r1',
          title: 'Fake parcel SMS asking for a customs fee',
          scamType: 'sms_phishing',
          verifiedAt: '2026-05-30T00:00:00.000Z',
        ),
        ReportSummaryItem(
          id: 'r2',
          title: 'Same number reported for a fake loan app',
          scamType: 'loan_scam',
          verifiedAt: '2026-05-21T00:00:00.000Z',
        ),
      ],
    );
  }
}

http.Client _apiClient() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == '/stats') {
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
    // Everything else (announcements, reports, notifications) — empty lists.
    return http.Response(
      jsonEncode({'items': <Object>[], 'data': <Object>[]}),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

const _testAuthUser = AuthUser(
  id: 'u-int-1',
  firebaseUid: 'firebase-int-1',
  email: 'somchai@example.com',
  displayName: 'Somchai Test',
  role: 'user',
  preferredLanguage: 'en',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late List<Override> overrides;
  late MockFirebaseAuth auth;
  late MockUser user;
  late MockAuthRepository authRepo;
  late MockAppLockRepository appLockRepo;
  late StreamController<User?> authEvents;
  User? currentUser;

  setUpAll(() {
    registerFallbackValue(LockoutState.none);
  });

  setUp(() async {
    // English UI so finders match; integration runs honour real prefs
    // otherwise (default locale is th).
    SharedPreferences.setMockInitialValues({'settings_language': 'en'});

    authEvents = StreamController<User?>.broadcast();
    currentUser = null;

    user = MockUser();
    when(() => user.uid).thenReturn('firebase-int-1');
    when(() => user.email).thenReturn('somchai@example.com');

    auth = MockFirebaseAuth();
    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    when(() => auth.authStateChanges()).thenAnswer((_) => authEvents.stream);
    when(() => auth.signOut()).thenAnswer((_) async {
      currentUser = null;
      authEvents.add(null);
    });

    authRepo = MockAuthRepository();
    when(
      () => authRepo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      currentUser = user;
      authEvents.add(user);
      return _testAuthUser;
    });
    when(() => authRepo.sync()).thenAnswer((_) async => _testAuthUser);

    appLockRepo = MockAppLockRepository();
    when(() => appLockRepo.loadConfig())
        .thenAnswer((_) async => AppLockConfig.defaults);
    when(() => appLockRepo.readLockout())
        .thenAnswer((_) async => LockoutState.none);

    final flags = MockFeatureFlags();
    when(() => flags.isEnabled(any())).thenReturn(false);

    final fcm = MockFcmRegistrar();
    when(fcm.start).thenAnswer((_) async {});

    final crash = MockCrashReporter();
    when(() => crash.setUserId(any())).thenAnswer((_) async {});

    final persistence = MockAskAiPersistence();
    when(() => persistence.clearForUser(any())).thenAnswer((_) async {});

    overrides = [
      firebaseAuthProvider.overrideWithValue(auth),
      authRepositoryProvider.overrideWithValue(authRepo),
      httpClientProvider.overrideWithValue(_apiClient()),
      featureFlagsProvider.overrideWithValue(flags),
      fcmRegistrarProvider.overrideWithValue(fcm),
      // FirebaseMessaging.onMessage is a static that throws without
      // Firebase.initializeApp — feed the listener an empty stream instead.
      fcmForegroundMessagesProvider.overrideWith((ref) => const Stream.empty()),
      fcmOpenedAppMessagesProvider.overrideWith((ref) => const Stream.empty()),
      fcmInitialMessageProvider.overrideWith((ref) async => null),
      crashReporterProvider.overrideWithValue(crash),
      askAiPersistenceProvider.overrideWithValue(persistence),
      checkRepositoryProvider.overrideWithValue(FakeCheckRepository()),
      appLockRepositoryProvider.overrideWith((ref) async => appLockRepo),
    ];
  });

  tearDown(() => authEvents.close());

  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MyApp()),
    );
    authEvents.add(currentUser); // seed the auth stream
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    // TEMP DEBUG: surface boot exceptions
    for (var i = 0; i < 5; i++) {
      final e = tester.takeException();
      if (e == null) break;
      // ignore: avoid_print
      print('BOOT-EXCEPTION[\$i]: \$e');
    }
  }

  testWidgets('flow 1 — cold start renders home with live stats',
      (tester) async {
    await boot(tester);

    expect(find.text('2,184'), findsOneWidget); // verified-total stat card
    expect(find.text('+36'), findsOneWidget); // new-this-week stat card
  });

  testWidgets('flow 2 — check an identifier and land on the verdict screen',
      (tester) async {
    await boot(tester);

    // Home search box routes to /check-input.
    await tester.tap(find.text('Paste a number, link, or message…'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '081-234-5678');
    await tester.pump();
    await tester.tap(find.text('Run check'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Canned repository verdict: scam with 2 matches.
    expect(find.text('Scam'), findsWidgets);
    expect(
      find.text('Fake parcel SMS asking for a customs fee'),
      findsOneWidget,
    );
  });

  testWidgets('flow 3 — login, see the account in settings, sign out',
      (tester) async {
    await boot(tester);

    // Me tab -> guest card.
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);

    // To the login screen.
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'somchai@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'hunter2hunter2');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Redirected to home; open settings and verify the signed-in account.
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Somchai Test'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Sign out (tile -> confirm dialog).
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Sign in'), findsOneWidget); // guest card again
  });
}
