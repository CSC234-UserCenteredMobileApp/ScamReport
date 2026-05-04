import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/cache/app_database.dart' as $db;
import '../domain/sms_alert.dart';
import 'sms_event_channel.dart';

class SmsScanRepository {
  SmsScanRepository({required http.Client http, required $db.AppDatabase db})
      : _http = http,
        _db = db;

  final http.Client _http;
  final $db.AppDatabase _db;

  Future<SmsAlert?> processEvent(SmsEvent event) async {
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$apiBaseUrl/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': 'text', 'payload': event.body}),
      );
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final verdict = data['verdict'] as String;
    if (verdict != 'scam' && verdict != 'suspicious') return null;

    final senderMasked = maskSender(event.sender);
    final bodyExcerpt =
        event.body.length > 80 ? event.body.substring(0, 80) : event.body;
    final now = DateTime.now();

    final id = await _db.into(_db.smsAlerts).insert(
          $db.SmsAlertsCompanion.insert(
            senderMasked: senderMasked,
            bodyExcerpt: bodyExcerpt,
            verdict: verdict,
            detectedAt: now,
          ),
        );

    return SmsAlert(
      id: id,
      senderMasked: senderMasked,
      bodyExcerpt: bodyExcerpt,
      verdict: verdict,
      detectedAt: now,
      isRead: false,
    );
  }

  Future<List<SmsAlert>> listAlerts() async {
    final rows = await (_db.select(_db.smsAlerts)
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .get();
    return rows
        .map((row) => SmsAlert(
              id: row.id,
              senderMasked: row.senderMasked,
              bodyExcerpt: row.bodyExcerpt,
              verdict: row.verdict,
              detectedAt: row.detectedAt,
              isRead: row.isRead,
            ))
        .toList();
  }

  static String maskSender(String sender) {
    final digits = sender.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return sender;
    final last4 = digits.substring(digits.length - 4);
    return 'XXXX-$last4';
  }
}
