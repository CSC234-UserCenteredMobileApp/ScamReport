import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';
import 'package:mobile/features/auth/presentation/forgot_password_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

Widget _wrap({required AuthRepository repo}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => ctx.push('/forgot-password'),
              child: const Text('go to forgot'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
    ),
  );
}

void main() {
  late _MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = _MockAuthRepository();
  });

  group('ForgotPasswordScreen', () {
    testWidgets('shows email field and send button initially', (tester) async {
      await tester.pumpWidget(_wrap(repo: mockRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go to forgot'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
    });

    testWidgets('success state replaces form after submit', (tester) async {
      when(() => mockRepo.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(repo: mockRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go to forgot'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('user-not-found shows success state to prevent email enumeration',
        (tester) async {
      when(() => mockRepo.sendPasswordResetEmail(any()))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      await tester.pumpWidget(_wrap(repo: mockRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go to forgot'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'ghost@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('Firebase error shows error banner', (tester) async {
      when(() => mockRepo.sendPasswordResetEmail(any()))
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      await tester.pumpWidget(_wrap(repo: mockRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go to forgot'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'bad-email');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('That email looks invalid.'), findsOneWidget);
    });

    testWidgets('"Back to login" pops back to previous screen', (tester) async {
      when(() => mockRepo.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(repo: mockRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go to forgot'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to login'));
      await tester.pumpAndSettle();

      expect(find.text('go to forgot'), findsOneWidget);
    });
  });
}
