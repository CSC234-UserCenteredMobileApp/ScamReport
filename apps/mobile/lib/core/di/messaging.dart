import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// Resolves the device's FCM token. Returns null if the user denied
// notifications or Firebase isn't initialised.
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final messaging = ref.watch(firebaseMessagingProvider);
  return messaging.getToken();
});

// Stream of foreground push messages. Listen from a widget to show in-app banners.
final fcmForegroundMessagesProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessage;
});

// Tap-on-push stream (app in background -> opened via notification). Routed
// through a provider so widgets never touch the FirebaseMessaging statics
// directly (overridable in tests; errors contained as AsyncError).
final fcmOpenedAppMessagesProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessageOpenedApp;
});

// The notification that cold-started the app, if any.
final fcmInitialMessageProvider = FutureProvider<RemoteMessage?>((ref) {
  return ref.watch(firebaseMessagingProvider).getInitialMessage();
});
