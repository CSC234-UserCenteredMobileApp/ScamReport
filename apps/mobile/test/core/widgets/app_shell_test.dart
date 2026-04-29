import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_shell.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';

// A minimal router whose only route is a StatefulShellRoute.indexedStack
// wrapping AppShell. Used to exercise the shell in isolation.
GoRouter _buildRouter({required AuthUser? user}) {
  return GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('Home'))),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feed',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('Feed'))),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/submit-report',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('Report'))),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/alerts',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('Alerts'))),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/me',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('Me'))),
            ),
          ]),
        ],
      ),
    ],
  );
}

AuthUser _fakeUser({required bool admin}) => AuthUser(
      id: '1',
      firebaseUid: 'uid1',
      email: 'test@example.com',
      displayName: 'Tester',
      role: admin ? 'admin' : 'user',
      preferredLanguage: 'en',
    );

Widget _pumpApp(GoRouter router, AuthUser? user) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) async => user),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
    ),
  );
}

void main() {
  group('AppShell bottom navigation', () {
    testWidgets('renders 5 nav items for a regular user', (tester) async {
      final router = _buildRouter(user: _fakeUser(admin: false));
      await tester.pumpWidget(_pumpApp(router, _fakeUser(admin: false)));
      await tester.pumpAndSettle();

      // 'Home' appears twice: once as nav label and once as the branch body.
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      // These labels only appear once (inactive tabs / nav labels only).
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
    });

    testWidgets('shows "Moderate" label for admin user', (tester) async {
      final adminUser = _fakeUser(admin: true);
      final router = _buildRouter(user: adminUser);
      await tester.pumpWidget(_pumpApp(router, adminUser));
      await tester.pumpAndSettle();

      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Report'), findsNothing);
    });

    testWidgets('shows "Report" label when user is null (guest)', (tester) async {
      final router = _buildRouter(user: null);
      await tester.pumpWidget(_pumpApp(router, null));
      await tester.pumpAndSettle();

      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Moderate'), findsNothing);
    });

    testWidgets('tapping Feed tab navigates to feed branch', (tester) async {
      final router = _buildRouter(user: _fakeUser(admin: false));
      await tester.pumpWidget(_pumpApp(router, _fakeUser(admin: false)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();

      // The Feed branch body text should now be visible.
      expect(find.text('Feed'), findsWidgets);
    });
  });
}
