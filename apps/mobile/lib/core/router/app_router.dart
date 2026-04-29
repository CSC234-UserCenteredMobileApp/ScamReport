import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../di/auth.dart';
import '../widgets/app_shell.dart';

// Routes that require an authenticated Firebase user. An unauthenticated
// visitor hitting one is redirected to /login. Add to this list as
// registered-user / admin features land.
const _authRequired = <String>{
  '/', // The home screen requires sign-in.
  // future: '/search', '/submit-report', '/my-reports', '/mod', ...
};

final goRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  // Refresh the router whenever Firebase auth state changes (sign-in,
  // sign-out, token refresh) so `redirect` re-evaluates.
  final refresh = _AuthRefreshNotifier(firebaseAuth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = firebaseAuth.currentUser;
      final loc = state.matchedLocation;
      final goingToAuth = loc == '/login' || loc == '/register';

      if (user != null && goingToAuth) {
        // Already signed in — keep the user out of the auth screens.
        return '/';
      }
      if (user == null && _authRequired.contains(loc)) {
        return '/login';
      }
      return null;
    },
    routes: [
      // -----------------------------------------------------------------------
      // Bottom-nav shell — 5 branches share the AppShell scaffold.
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          // 0 — Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomeScreen(),
            ),
          ]),
          // 1 — Feed
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feed',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('Feed — coming soon')),
              ),
            ),
          ]),
          // 2 — Report / Moderate
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/submit-report',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('Report — coming soon')),
              ),
            ),
          ]),
          // 3 — Alerts
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/alerts',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('Alerts — coming soon')),
              ),
            ),
          ]),
          // 4 — Me
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/me',
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),

      // -----------------------------------------------------------------------
      // Full-screen flows — no bottom nav (outside the shell).
      // -----------------------------------------------------------------------
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/check-input',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Check input — coming soon')),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Search — coming soon')),
        ),
      ),
      GoRoute(
        path: '/announcement-detail/:id',
        builder: (_, s) => Scaffold(
          body: Center(
            child: Text('Announcement ${s.pathParameters['id']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/report-detail/:id',
        builder: (_, s) => Scaffold(
          body: Center(
            child: Text('Report ${s.pathParameters['id']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/my-reports',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('My reports — coming soon')),
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Privacy policy — coming soon')),
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Terms of service — coming soon')),
        ),
      ),
    ],
  );
});

// Bridges a Stream<User?> into a Listenable so go_router can refresh on
// auth state changes. Notifies once on construction to evaluate the initial
// route, then once per stream event.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<User?> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
