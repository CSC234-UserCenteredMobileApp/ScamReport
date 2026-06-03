import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_providers.dart';

/// Bridges OS app-lifecycle events into the app-lock controller. Registered by
/// MyApp via WidgetsBinding.
class AppLockObserver with WidgetsBindingObserver {
  AppLockObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycle(
      state,
      _ref.read(appLockControllerProvider.notifier),
      enabled:
          _ref.read(appLockControllerProvider).valueOrNull?.config.enabled ??
              false,
      setObscured: (v) =>
          _ref.read(appLockObscuredProvider.notifier).state = v,
      now: DateTime.now(),
    );
  }
}

/// Pure mapping from a lifecycle transition to controller calls + the privacy
/// cover flag. Extracted so it can be unit-tested without a WidgetRef.
///
/// The biometric prompt itself fires inactive/paused/resumed; while an auth is
/// in flight the controller ignores the background timer, and we also skip the
/// privacy cover so it doesn't flicker over the prompt.
@visibleForTesting
void handleLifecycle(
  AppLifecycleState state,
  AppLockController controller, {
  required bool enabled,
  required void Function(bool) setObscured,
  required DateTime now,
}) {
  switch (state) {
    case AppLifecycleState.inactive:
    case AppLifecycleState.paused:
    case AppLifecycleState.hidden:
      controller.onBackgrounded(now);
      if (enabled && !controller.authInFlight) setObscured(true);
    case AppLifecycleState.resumed:
      controller.onResumed(now);
      setObscured(false);
    case AppLifecycleState.detached:
      break;
  }
}
