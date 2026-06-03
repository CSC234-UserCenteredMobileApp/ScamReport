import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';

import 'core/di/auth.dart';
import 'core/di/firebase.dart';
import 'core/notifications/fcm_registrar.dart';
import 'core/notifications/foreground_listener.dart';
import 'core/observability/crash_reporter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/app_lock/presentation/app_lock_gate.dart';
import 'features/app_lock/presentation/app_lock_lifecycle.dart';
import 'features/ask_ai/presentation/ask_ai_providers.dart';
import 'features/settings/presentation/settings_providers.dart';
import 'features/settings/presentation/theme_mode_x.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await initializeFirebase();
  if (firebaseReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AppLockObserver _appLockObserver;

  @override
  void initState() {
    super.initState();
    // FcmRegistrar listens to auth state internally; safe to fire-and-forget.
    ref.read(fcmRegistrarProvider).start();

    // App-lock: relock on resume past the timeout + paint the privacy cover
    // while backgrounded. The controller's initial config load is kicked off
    // by AppLockGate watching the provider in build().
    _appLockObserver = AppLockObserver(ref);
    WidgetsBinding.instance.addObserver(_appLockObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appLockObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    // Sign-out drift hygiene: when authState becomes null, purge the Ask AI
    // composer snapshot so the next account doesn't see this device's stale
    // chat state. iter-5 multi-device hardening.
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (prev, next) {
      final wasSignedIn = prev?.valueOrNull != null;
      final isSignedOut = next.valueOrNull == null;
      if (wasSignedIn && isSignedOut) {
        final persistence = ref.read(askAiPersistenceProvider);
        // ignore the future — purge is best-effort + idempotent.
        persistence.clearForUser(prev?.valueOrNull?.uid as String? ?? '');
      }
    });

    // Tag every Crashlytics report with the current Firebase uid (empty
    // string when signed out) so support can pivot incidents by user. We
    // also seed it from the build-time snapshot since `ref.listen` only
    // fires on subsequent changes.
    final reporter = ref.read(crashReporterProvider);
    reporter.setUserId(ref.read(authStateProvider).valueOrNull?.uid);
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (prev, next) {
      reporter.setUserId(next.valueOrNull?.uid);
    });

    return MaterialApp.router(
      title: 'ScamReport',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: settings?.themeMode.material ?? ThemeMode.system,
      locale: settings != null ? Locale(settings.language) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) {
        // AppLockGate is outermost so the lock/privacy cover sits above all
        // app content, including notification overlays.
        return AppLockGate(
          child:
              ForegroundNotificationListener(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
