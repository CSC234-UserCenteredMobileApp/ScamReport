import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SmsEvent {
  const SmsEvent({required this.sender, required this.body});

  final String sender;
  final String body;
}

const _channel = EventChannel('com.scamreport/sms_events');

final smsEventChannelProvider = Provider<Stream<SmsEvent>>((ref) {
  return _channel.receiveBroadcastStream().map((event) {
    final map = Map<String, dynamic>.from(event as Map);
    return SmsEvent(
      sender: map['sender'] as String,
      body: map['body'] as String,
    );
  });
});
