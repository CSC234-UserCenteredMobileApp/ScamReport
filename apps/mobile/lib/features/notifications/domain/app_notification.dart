enum NotificationKind {
  reportVerified,
  reportRejected,
  reportFlagged,
  unknown;

  static NotificationKind fromWire(String raw) {
    switch (raw) {
      case 'report_verified':
        return NotificationKind.reportVerified;
      case 'report_rejected':
        return NotificationKind.reportRejected;
      case 'report_flagged':
        return NotificationKind.reportFlagged;
      default:
        return NotificationKind.unknown;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.reportId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? reportId;
  final bool isRead;
  final DateTime createdAt;
}

class NotificationListData {
  const NotificationListData({required this.items, required this.unreadCount});

  final List<AppNotification> items;
  final int unreadCount;
}
