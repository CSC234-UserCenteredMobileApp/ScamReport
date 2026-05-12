import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';

import 'core/di/auth.dart';
import 'core/di/firebase.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/ask_ai/presentation/ask_ai_providers.dart';
import 'features/settings/presentation/settings_providers.dart';
import 'features/share_target/presentation/share_target_handler.dart';

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
  @override
  void initState() {
    super.initState();
    // Defer one frame so goRouterProvider (and Remote Config) are initialised.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareTargetHandler.init(ref);
    });
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

    return MaterialApp.router(
      title: 'ScamReport',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: settings?.themeMode ?? ThemeMode.system,
      locale: settings != null ? Locale(settings.language) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
