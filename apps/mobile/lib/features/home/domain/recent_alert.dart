enum AlertCategory { fraudAlert, tips, platformUpdate }

class RecentAlert {
  const RecentAlert({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAt,
  });
  final String id;
  final String title;
  final AlertCategory category;
  final DateTime publishedAt;
}
