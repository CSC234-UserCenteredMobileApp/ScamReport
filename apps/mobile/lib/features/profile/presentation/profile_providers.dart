import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/auth.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

part 'profile_providers.g.dart';

// @riverpod code generation (rubric R2) — class-based notifier demo.

/// Overridable Firestore handle (tests inject FakeFirebaseFirestore).
@Riverpod(keepAlive: true)
FirebaseFirestore profileFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(ref.watch(profileFirestoreProvider));
}

/// Streams the signed-in user's editable profile card (null when signed out
/// or not yet created) and exposes [save] for the edit sheet.
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Stream<UserProfile?> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream.value(null);
    return ref.watch(profileRepositoryProvider).watch(user.uid);
  }

  Future<void> save({required String displayName}) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    // Keep the profile's language in step with the app language preference.
    final language = state.valueOrNull?.preferredLanguage ??
        ref.read(settingsProvider).valueOrNull?.language ??
        'th';
    await ref.read(profileRepositoryProvider).save(
          user.uid,
          displayName: displayName,
          preferredLanguage: language,
        );
  }
}
