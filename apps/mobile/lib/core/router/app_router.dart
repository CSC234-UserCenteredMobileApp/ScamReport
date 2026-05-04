import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/alerts/presentation/announcement_detail_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/legal/presentation/privacy_screen.dart';
import '../../features/legal/presentation/terms_screen.dart';
import '../../features/moderation/presentation/admin_review_screen.dart';
import '../../features/moderation/presentation/mod_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../di/auth.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_gate.dart';

// Routes that require an authenticated Firebase user. An unauthenticated
// visitor hitting one is redirected to /login. Add to this list as
// registered-user / admin features land.
const _authRequired = <String>{
  // Home and feed are public. Auth-gated routes show EmptyGate inline
  // rather than redirecting so the bottom nav stays visible.
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
              builder: (_, __) => const FeedScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) =>
                      ReportDetailScreen(id: s.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          // 2 — Ask AI / Moderate (admin)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ask-ai',
              builder: (_, __) => Consumer(
                builder: (context, ref, _) {
                  final user = ref.watch(currentUserProvider).valueOrNull;
                  if (user?.isAdmin == true) return const ModScreen();
                  if (user == null) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Ask AI')),
                      body: EmptyGate(
                        icon: Icons.auto_awesome_outlined,
                        heading: 'Sign in to use Ask AI',
                        body: 'Ask AI helps you identify scams and get guidance on what to do next.',
                        primaryLabel: 'Sign in or register',
                        onPrimary: () => context.push('/login'),
                      ),
                    );
                  }
                  return const Scaffold(
                    body: Center(child: Text('Ask AI — coming soon')),
                  );
                },
              ),
              routes: [
                GoRoute(
                  path: 'review/:id',
                  builder: (_, s) =>
                      AdminReviewScreen(reportId: s.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          // 3 — Alerts
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/alerts',
              builder: (_, __) => const AlertsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) => AnnouncementDetailScreen(
                    id: s.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          // 4 — Me
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/me',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'privacy',
                  builder: (_, __) => const PrivacyScreen(),
                ),
                GoRoute(
                  path: 'terms',
                  builder: (_, __) => const TermsScreen(),
                ),
              ],
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
        path: '/submit-report',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Submit report — coming soon')),
        ),
      ),
      GoRoute(
        path: '/check-input',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Check input — coming soon')),
        ),
      ),
      GoRoute(
        path: '/announcement-detail/:id',
        builder: (_, s) => AnnouncementDetailScreen(
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/report-detail/:id',
        builder: (_, s) =>
            ReportDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/my-reports',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('My reports — coming soon')),
        ),
      ),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms',   builder: (_, __) => const TermsScreen()),
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
