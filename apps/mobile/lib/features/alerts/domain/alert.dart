import '../../home/domain/recent_alert.dart'; // reuse AlertCategory enum — do NOT duplicate it
import '../../sms_scan/domain/sms_alert.dart';

class AlertAttachment {
  const AlertAttachment({
    required this.id,
    required this.url,
    required this.kind,
    required this.mimeType,
    required this.sizeBytes,
  });
  final String id;
  final String url;
  final String kind; // 'image' | 'pdf'
  final String mimeType;
  final int sizeBytes;
}

class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.category,
    required this.publishedAt,
    required this.slug,
    this.attachments = const [],
    this.firstImageUrl,
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
  final List<AlertAttachment> attachments;
  final String? firstImageUrl;
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
