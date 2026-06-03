// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileFirestoreHash() => r'8f0f3069c796c83ca3e08a528f743ee649112545';

/// Overridable Firestore handle (tests inject FakeFirebaseFirestore).
///
/// Copied from [profileFirestore].
@ProviderFor(profileFirestore)
final profileFirestoreProvider = Provider<FirebaseFirestore>.internal(
  profileFirestore,
  name: r'profileFirestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileFirestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileFirestoreRef = ProviderRef<FirebaseFirestore>;
String _$profileRepositoryHash() => r'ce74cfafb019e9c4f52d5eee1cc0387fab65e0c5';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider = Provider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = ProviderRef<ProfileRepository>;
String _$profileControllerHash() => r'd2670be3bf2cb3c0d0bf3196baaa4270b39d95b5';

/// Streams the signed-in user's editable profile card (null when signed out
/// or not yet created) and exposes [save] for the edit sheet.
///
/// Copied from [ProfileController].
@ProviderFor(ProfileController)
final profileControllerProvider =
    AutoDisposeStreamNotifierProvider<ProfileController, UserProfile?>.internal(
  ProfileController.new,
  name: r'profileControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileController = AutoDisposeStreamNotifier<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
