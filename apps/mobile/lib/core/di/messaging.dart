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
