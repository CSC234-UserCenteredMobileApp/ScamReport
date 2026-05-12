enum AlertCategory { fraudAlert, tips, platformUpdate, smsAlert }

class RecentAlert {
  const RecentAlert({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAt,
    this.firstImageStoragePath,
  });
  final String id;
  final String title;
  final AlertCategory category;
  final DateTime publishedAt;
  final String? firstImageStoragePath;
}
