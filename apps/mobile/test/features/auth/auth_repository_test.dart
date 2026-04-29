import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockAuthApi extends Mock implements AuthApi {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockAuthApi mockAuthApi;
  late AuthRepository repository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockAuthApi = MockAuthApi();
    repository = AuthRepository(mockFirebaseAuth, mockAuthApi);
  });

  const testUser = AuthUser(
    id: '1',
    firebaseUid: 'uid1',
    email: 'test@example.com',
    displayName: 'Tester',
    role: 'user',
    preferredLanguage: 'en',
  );

  group('AuthRepository', () {
    test('signInWithEmail calls firebase and syncs', () async {
      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          )).thenAnswer((_) async => MockUserCredential());
      when(() => mockAuthApi.sync()).thenAnswer((_) async => testUser);

      final result = await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, testUser);
      verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          )).called(1);
      verify(() => mockAuthApi.sync()).called(1);
    });

    test('registerWithEmail calls firebase, updates display name, and syncs', () async {
      final mockUser = MockUser();
      final mockCred = MockUserCredential();
      when(() => mockCred.user).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      
      when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          )).thenAnswer((_) async => mockCred);
      when(() => mockAuthApi.sync()).thenAnswer((_) async => testUser);

      final result = await repository.registerWithEmail(
        email: 'test@example.com',
        password: 'password',
        displayName: 'Tester',
      );

      expect(result, testUser);
      verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          )).called(1);
      verify(() => mockUser.updateDisplayName('Tester')).called(1);
      verify(() => mockAuthApi.sync()).called(1);
    });

    test('signOut calls firebase signOut', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
    });

    test('sync calls api sync', () async {
      when(() => mockAuthApi.sync()).thenAnswer((_) async => testUser);

      final result = await repository.sync();

      expect(result, testUser);
      verify(() => mockAuthApi.sync()).called(1);
    });
  });
}
