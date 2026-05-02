import '../../home/domain/recent_alert.dart'; // reuse AlertCategory enum — do NOT duplicate it

class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.category,
    required this.publishedAt,
    required this.slug,
  });

  final String id;
  final String title;
  final String excerpt;
  final String body;
  final AlertCategory category;
  final DateTime publishedAt;
  final String slug;
}
