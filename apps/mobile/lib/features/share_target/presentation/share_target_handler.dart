import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../check/domain/check_result.dart';
import '../../check/presentation/check_providers.dart';
import '../domain/share_input.dart';
import 'share_target_providers.dart';

const _kChannelId = 'share_check_results';
const _kNotifId = 42;

final _plugin = FlutterLocalNotificationsPlugin();

// Package-level router reference for notification tap navigation.
// Set by app_router.dart after GoRouter is created.
void Function(String path)? _onNotificationTap;

void setShareNotificationNavigator(void Function(String path) fn) {
  _onNotificationTap = fn;
}

class ShareTargetHandler {
  // ---------------------------------------------------------------------------
  // Public entry point — call once from MyApp.initState after first frame.
  // ---------------------------------------------------------------------------
  static Future<void> init(WidgetRef ref) async {
    final enabled = ref.read(featureFlagProvider('enable_share_target'));
    if (!enabled) return;

    await _initNotifications();

    final service = ref.read(shareIntentServiceProvider);

    final initial = await service.getInitial();
    if (initial != null) await _handle(ref, initial);

    service.stream.listen((input) => _handle(ref, input));
  }

  // ---------------------------------------------------------------------------
  // Exposed as static for unit testing.
  // ---------------------------------------------------------------------------
  static String truncateForNotification(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  static (String title, String emoji) verdictNotificationLabel(
          String verdict) =>
      switch (verdict) {
        'scam' => ('Scam', '⚠️'),
        'suspicious' => ('Suspicious', '⚠️'),
        'safe' => ('Safe', '✓'),
        _ => ('Unknown', '?'),
      };

  // ---------------------------------------------------------------------------
  // Internal helpers.
  // ---------------------------------------------------------------------------
  static Future<void> _handle(WidgetRef ref, ShareInput input) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _notify(
        title: 'Sign in to check this',
        body: truncateForNotification(input.text, 60),
        payload: '/login',
      );
      return;
    }

    await _notify(
      title: 'Checking…',
      body: truncateForNotification(input.text, 60),
      payload: null,
    );

    try {
      final query = CheckQuery(
        payload: input.text,
        type: input.kind,
        source: 'share',
      );
      final result = await ref.read(checkRepositoryProvider).runCheck(query);
      final (title, emoji) = verdictNotificationLabel(result.verdict);
      await _notify(
        title: '$emoji $title',
        body: '"${truncateForNotification(input.text, 60)}" — tap to see details',
        payload:
            '/verdict?q=${Uri.encodeComponent(input.text)}&kind=${input.kind}',
      );
    } catch (_) {
      await _notify(
        title: 'Check failed',
        body: 'Could not analyse the content. Tap to try manually.',
        payload: '/check-input?text=${Uri.encodeComponent(input.text)}',
      );
    }
  }

  static Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (details) {
        final path = details.payload;
        if (path != null && path.isNotEmpty) {
          _onNotificationTap?.call(path);
        }
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _kChannelId,
          'Scam Check Results',
          importance: Importance.high,
        ));
  }

  static Future<void> _notify({
    required String title,
    required String body,
    required String? payload,
  }) =>
      _plugin.show(
        _kNotifId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            'Scam Check Results',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
          ),
        ),
        payload: payload,
      );
}
