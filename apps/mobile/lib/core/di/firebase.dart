import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Initialise Firebase. Returns true on success, false if config files are
// missing or init throws — so the rest of the app keeps working in setups
// that haven't placed google-services.json / GoogleService-Info.plist yet.
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    developer.log(
      '[firebase] init skipped — see HOW_TO_CONTRIBUTE.md §3 for config files',
      name: 'firebase',
      error: e,
      stackTrace: st,
    );
    return false;
  }

  // Ask for FCM permission. iOS requires this before getToken() works; on
  // Android the platform grants it implicitly. If the user denies, getToken()
  // returns null and the rest of the app still functions.
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  return true;
}
