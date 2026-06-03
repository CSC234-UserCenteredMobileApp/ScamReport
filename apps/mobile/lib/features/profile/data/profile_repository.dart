import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/user_profile.dart';

/// Direct Firestore client for `profiles/{uid}` — intentionally NOT routed
/// through the API: this is the rules-validated client-write surface
/// (firestore.rules enforces owner isolation, field whitelist via
/// diff().affectedKeys(), and request.time == updatedAt).
class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('profiles').doc(uid);

  Stream<UserProfile?> watch(String uid) => _doc(uid).snapshots().map(_fromSnap);

  Future<UserProfile?> fetch(String uid) async => _fromSnap(await _doc(uid).get());

  /// Merge-write so a partial update only touches the whitelisted keys —
  /// pairs with the rules' diff().affectedKeys() check. `updatedAt` MUST be
  /// FieldValue.serverTimestamp(): the rules reject client-supplied clocks.
  Future<void> save(
    String uid, {
    required String displayName,
    required String preferredLanguage,
  }) {
    return _doc(uid).set(
      <String, dynamic>{
        'displayName': displayName.trim(),
        'preferredLanguage': preferredLanguage,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static UserProfile? _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;
    return UserProfile(
      displayName: (data['displayName'] as String?) ?? '',
      preferredLanguage: (data['preferredLanguage'] as String?) ?? 'th',
      avatarUrl: data['avatarUrl'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
