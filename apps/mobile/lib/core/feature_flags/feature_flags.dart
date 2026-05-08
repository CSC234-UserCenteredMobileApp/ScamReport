import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around Remote Config so widgets and providers can read flags
/// without depending on `firebase_remote_config` directly. Defaults are
/// always false in code (see core/di/firebase.dart) — promote a flag by
/// flipping it in the Firebase Console.
class FeatureFlags {
  FeatureFlags(this._rc);
  final FirebaseRemoteConfig _rc;
  bool isEnabled(String key) => _rc.getBool(key);
}

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags(FirebaseRemoteConfig.instance);
});

/// Family provider so widgets can do `ref.watch(featureFlagProvider('foo'))`.
/// Read-only — no listener wiring; flag changes pick up on the next
/// fetchAndActivate() call (cold start or scheduled refresh).
final featureFlagProvider = Provider.family<bool, String>((ref, key) {
  return ref.watch(featureFlagsProvider).isEnabled(key);
});
