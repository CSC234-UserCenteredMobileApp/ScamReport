import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/example/presentation/example_screen.dart';
import '../di/auth.dart';

// Routes that require an authenticated Firebase user. An unauthenticated
// visitor hitting one is redirected to /login. Add to this list as
// registered-user / admin features land.
const _authRequired = <String>{
  // future: '/search', '/submit', '/my-reports', '/mod', ...
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
      GoRoute(path: '/', builder: (_, __) => const ExampleScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
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
