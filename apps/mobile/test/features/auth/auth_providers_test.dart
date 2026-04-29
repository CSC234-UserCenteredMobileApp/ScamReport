import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/di/auth.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('currentUserProvider', () {
    test('returns null when firebase user is null', () async {
      final container = ProviderContainer(
        overrides: [
          // Override authStateProvider directly with an AsyncValue so the
          // dependent FutureProvider resolves immediately.
          authStateProvider.overrideWith(
            (ref) => Stream<User?>.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Listen to force the provider to build.
      container.listen(currentUserProvider, (_, __) {});

      // Allow the stream event + future to propagate.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = container.read(currentUserProvider).valueOrNull;
      expect(result, isNull);
    });

    test('calls repository sync when firebase user is present', () async {
      final mockUser = MockUser();
      const testUser = AuthUser(
        id: '1',
        firebaseUid: 'uid1',
        email: 'test@example.com',
        displayName: 'Tester',
        role: 'user',
        preferredLanguage: 'en',
      );

      when(() => mockAuthRepository.sync()).thenAnswer((_) async => testUser);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream<User?>.value(mockUser),
          ),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      // Listen to force the provider to build.
      container.listen(currentUserProvider, (_, __) {});

      // Allow the stream event + future to propagate.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = container.read(currentUserProvider).valueOrNull;
      expect(result, testUser);
      verify(() => mockAuthRepository.sync()).called(1);
    });
  });
}
