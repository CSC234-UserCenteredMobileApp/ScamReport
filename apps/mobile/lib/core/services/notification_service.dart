import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/sms_scan/domain/sms_alert.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'sms_scam_alerts',
          'SMS Scam Alerts',
          description:
              'Warns when an incoming SMS is detected as scam or suspicious',
          importance: Importance.high,
        ));
  }

  Future<void> showSmsAlert(SmsAlert alert) async {
    final isScam = alert.verdict == 'scam';
    await _plugin.show(
      alert.id,
      isScam ? 'Scam SMS Detected' : 'Suspicious SMS',
      '${alert.senderMasked}: ${alert.bodyExcerpt}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sms_scam_alerts',
          'SMS Scam Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
