import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_user.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._firebaseAuth, this._api);

  final FirebaseAuth _firebaseAuth;
  final AuthApi _api;

  // Sign in with email/password, then sync the backend users row.
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _api.sync();
  }

  // Create a Firebase account, set an optional display name, then sync.
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await cred.user?.updateDisplayName(trimmed);
    }
    return _api.sync();
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  // Re-sync the backend user without re-authenticating. Useful after the
  // mobile app rehydrates and Firebase already has a current user.
  Future<AuthUser> sync() => _api.sync();
}
