import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_lock_runtime.dart';
import 'app_lock_providers.dart';
import 'lock_screen.dart';
import 'widgets/app_lock_cover.dart';

/// Wraps the app's router child. Keeps the child mounted at all times (so the
/// navigation stack / shell state survive a re-lock) and paints an opaque
/// cover on top when the app is loading, locked, or backgrounded.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appLockControllerProvider);
    final obscured = ref.watch(appLockObscuredProvider);

    // Splash on the very first load (no prior value) AND on a controller
    // error — the lock must fail CLOSED: if we cannot determine the lock
    // state we show the opaque cover rather than app content. A background
    // refresh keeps the last known state instead of flashing the splash.
    final showSplash = !async.hasValue && (async.isLoading || async.hasError);
    final rt = async.valueOrNull;
    final locked = rt != null && rt.status != AppLockStatus.unlocked;

    return Stack(
      children: [
        child,
        if (showSplash)
          const Positioned.fill(
            child: AppLockCover(key: Key('app-lock-splash')),
          )
        else if (locked)
          const Positioned.fill(child: LockScreen()),
        // Privacy cover sits above everything while backgrounded.
        if (obscured && !showSplash)
          const Positioned.fill(child: AppLockCover()),
      ],
    );
  }
}
