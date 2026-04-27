// TODO: replace with a generated type once scripts/codegen.sh is wired up.

class AuthUser {
  const AuthUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.preferredLanguage,
  });

  final String id;
  final String firebaseUid;
  final String? email;
  final String? displayName;
  final String role; // 'user' | 'admin'
  final String preferredLanguage; // 'th' | 'en'

  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      role: json['role'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
    );
  }
}
