import 'app_notification.dart';

abstract class NotificationsRepository {
  Future<NotificationListData> listInbox();
  Future<int> markRead(List<String> ids);
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? appVersion,
  });
  Future<void> unregisterDevice(String fcmToken);
}
