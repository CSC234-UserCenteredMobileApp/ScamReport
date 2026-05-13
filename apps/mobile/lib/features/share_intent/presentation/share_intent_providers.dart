import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/share_intent_service.dart';
import '../domain/shared_payload.dart';

/// Remote Config key — registered with default `false` in
/// `core/di/firebase.dart` and flipped on from the Firebase Console.
const shareTargetFlagKey = 'enable_share_target';

final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  return PluginShareIntentService();
});

/// Emits the next warm share. Listener side-effects route to /verdict.
final shareIntentStreamProvider = StreamProvider<SharedPayload>((ref) {
  return ref.watch(shareIntentServiceProvider).stream();
});
