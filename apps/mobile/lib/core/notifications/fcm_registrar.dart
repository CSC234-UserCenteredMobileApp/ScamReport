import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/auth.dart';
import '../di/cache.dart';
import '../di/messaging.dart';
import '../../features/notifications/presentation/notifications_providers.dart';

const String _kLastSentTokenKey = 'fcm:last_sent_token';
const String _kLastSentUidKey = 'fcm:last_sent_uid';

// Keeps the device's FCM token in sync with the backend so the server can
// actually deliver report-status pushes. Without this, every `sendFcmToUser`
// call on the API side finds zero FcmDevice rows and silently drops.
//
// Lifecycle:
//   - On sign-in: post the current token to POST /me/fcm-tokens (skip if the
//     same token was already sent for the same user — saves a request per
//     cold start).
//   - On onTokenRefresh: post the new token.
//   - On sign-out: best-effort DELETE the prior token so a borrowed device
//     stops receiving the prior user's pushes.
class FcmRegistrar {
  FcmRegistrar(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authSub;

  Future<void> start() async {
    final auth = _ref.read(firebaseAuthProvider);
    _authSub = auth.authStateChanges().listen((user) async {
      if (user == null) {
        await _onSignedOut();
      } else {
        await _syncForUser(user.uid);
      }
    });

    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;
      await _postIfChanged(user.uid, token);
    });
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _authSub?.cancel();
  }

  Future<void> _syncForUser(String uid) async {
    try {
      final token = await _ref.read(fcmTokenProvider.future);
      if (token == null || token.isEmpty) return;
      await _postIfChanged(uid, token);
    } catch (e) {
      debugPrint('[fcm-registrar] sync failed: $e');
    }
  }

  Future<void> _postIfChanged(String uid, String token) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final lastToken = prefs.getString(_kLastSentTokenKey);
    final lastUid = prefs.getString(_kLastSentUidKey);
    if (lastToken == token && lastUid == uid) return;

    try {
      await _ref.read(notificationsRepositoryProvider).registerDevice(
            fcmToken: token,
            platform: _currentPlatform(),
          );
      await prefs.setString(_kLastSentTokenKey, token);
      await prefs.setString(_kLastSentUidKey, uid);
    } catch (e) {
      debugPrint('[fcm-registrar] register failed: $e');
    }
  }

  Future<void> _onSignedOut() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final lastToken = prefs.getString(_kLastSentTokenKey);
      if (lastToken != null && lastToken.isNotEmpty) {
        await _ref
            .read(notificationsRepositoryProvider)
            .unregisterDevice(lastToken);
      }
      await prefs.remove(_kLastSentTokenKey);
      await prefs.remove(_kLastSentUidKey);
    } catch (e) {
      debugPrint('[fcm-registrar] unregister failed: $e');
    }
  }

  String _currentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}

final fcmRegistrarProvider = Provider<FcmRegistrar>((ref) {
  final registrar = FcmRegistrar(ref);
  ref.onDispose(() {
    registrar.dispose();
  });
  return registrar;
});
