import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';
import 'notifications_api_client.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._api);

  final NotificationsApiClient _api;

  @override
  Future<NotificationListData> listInbox() async {
    final raw = await _api.fetchInbox();
    final items = (raw['items'] as List<dynamic>)
        .map((e) => _mapNotification(e as Map<String, dynamic>))
        .toList();
    return NotificationListData(
      items: items,
      unreadCount: raw['unreadCount'] as int,
    );
  }

  @override
  Future<int> markRead(List<String> ids) async {
    final raw = await _api.markRead(ids);
    return raw['unreadCount'] as int;
  }

  @override
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? appVersion,
  }) {
    return _api.registerToken(
      fcmToken: fcmToken,
      platform: platform,
      appVersion: appVersion,
    );
  }

  @override
  Future<void> unregisterDevice(String fcmToken) =>
      _api.unregisterToken(fcmToken);

  AppNotification _mapNotification(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        kind: NotificationKind.fromWire(m['kind'] as String),
        title: m['title'] as String,
        body: m['body'] as String,
        reportId: m['reportId'] as String?,
        isRead: m['isRead'] as bool,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
