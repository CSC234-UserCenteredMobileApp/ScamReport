/// Editable public profile card, stored at Firestore `profiles/{uid}` — the
/// one client-writable Firestore surface (see firestore.rules). Pure Dart.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.preferredLanguage,
    this.avatarUrl,
    this.updatedAt,
  });

  final String displayName;
  final String preferredLanguage; // 'en' | 'th'
  final String? avatarUrl;
  final DateTime? updatedAt;

  /// Mirror of the firestore.rules constraint — enforced client-side for
  /// instant feedback, server-side by the rules for integrity.
  static const int maxDisplayNameLength = 50;

  static bool isValidDisplayName(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxDisplayNameLength;
  }

  UserProfile copyWith({
    String? displayName,
    String? preferredLanguage,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
