import '../../home/domain/recent_alert.dart'; // reuse AlertCategory enum — do NOT duplicate it
import '../../sms_scan/domain/sms_alert.dart';

class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.category,
    required this.publishedAt,
    required this.slug,
    this.senderMasked,
    this.verdict,
  });

  final String id;
  final String title;
  final String excerpt;
  final String body;
  final AlertCategory category;
  final DateTime publishedAt;
  final String slug;
  final String? senderMasked;
  final String? verdict;

  factory Alert.fromSmsAlert(SmsAlert sms) {
    return Alert(
      id: 'sms-${sms.id}',
      title: sms.senderMasked,
      excerpt: sms.bodyExcerpt,
      body: sms.bodyExcerpt,
      category: AlertCategory.smsAlert,
      publishedAt: sms.detectedAt,
      slug: '',
      senderMasked: sms.senderMasked,
      verdict: sms.verdict,
    );
  }
}
