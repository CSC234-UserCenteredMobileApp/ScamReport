import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockFirebaseAuth mockFirebaseAuth;
  late AuthApi authApi;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockFirebaseAuth = MockFirebaseAuth();
    authApi = AuthApi(mockHttpClient, mockFirebaseAuth);
    
    registerFallbackValue(Uri());
  });

  group('AuthApi', () {
    const testUser = AuthUser(
      id: '1',
      firebaseUid: 'uid1',
      email: 'test@example.com',
      displayName: 'Tester',
      role: 'user',
      preferredLanguage: 'en',
    );

    test('sync throws if no firebase user', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      expect(() => authApi.sync(), throwsStateError);
    });

    test('sync calls backend and returns AuthUser', () async {
      final mockUser = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken()).thenAnswer((_) async => 'fake_token');

      final responseBody = jsonEncode({
        'user': {
          'id': '1',
          'firebaseUid': 'uid1',
          'email': 'test@example.com',
          'displayName': 'Tester',
          'role': 'user',
          'preferredLanguage': 'en',
        }
      });

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await authApi.sync();

      expect(result.id, testUser.id);
      expect(result.email, testUser.email);
      
      verify(() => mockHttpClient.post(
            Uri.parse('$apiBaseUrl/auth/sync'),
            headers: {
              'Authorization': 'Bearer fake_token',
              'content-type': 'application/json',
            },
          )).called(1);
    });

    test('sync throws if backend returns non-200', () async {
      final mockUser = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken()).thenAnswer((_) async => 'fake_token');

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('error', 500));

      expect(() => authApi.sync(), throwsException);
    });

    test('sync throws if token is null', () async {
      final mockUser = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken()).thenAnswer((_) async => null);

      expect(() => authApi.sync(), throwsStateError);
    });
  });
}
