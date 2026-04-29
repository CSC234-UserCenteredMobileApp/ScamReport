import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';

void main() {
  group('AuthUser', () {
    const userJson = {
      'id': '123',
      'firebaseUid': 'abc',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'role': 'user',
      'preferredLanguage': 'en',
    };

    const adminJson = {
      'id': '456',
      'firebaseUid': 'def',
      'email': 'admin@example.com',
      'displayName': 'Admin User',
      'role': 'admin',
      'preferredLanguage': 'th',
    };

    test('fromJson creates a user correctly', () {
      final user = AuthUser.fromJson(userJson);
      expect(user.id, '123');
      expect(user.firebaseUid, 'abc');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.role, 'user');
      expect(user.preferredLanguage, 'en');
      expect(user.isAdmin, isFalse);
    });

    test('isAdmin returns true for admin role', () {
      final admin = AuthUser.fromJson(adminJson);
      expect(admin.isAdmin, isTrue);
    });

    test('works with null optional fields', () {
      final minimalJson = {
        'id': '789',
        'firebaseUid': 'ghi',
        'email': null,
        'displayName': null,
        'role': 'user',
        'preferredLanguage': 'en',
      };
      final user = AuthUser.fromJson(minimalJson);
      expect(user.email, isNull);
      expect(user.displayName, isNull);
    });
  });
}
