import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/features/sms_scan/domain/sms_alert.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

SmsAlert _alert({required String verdict}) => SmsAlert(
      id: 1,
      senderMasked: 'XXXX-5678',
      bodyExcerpt: 'Click now to claim',
      verdict: verdict,
      detectedAt: DateTime(2026, 5, 5),
      isRead: false,
    );

void main() {
  late _MockPlugin mockPlugin;
  late NotificationService service;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    registerFallbackValue(const NotificationDetails(
      android: AndroidNotificationDetails('ch', 'ch'),
    ));
  });

  setUp(() {
    mockPlugin = _MockPlugin();
    service = NotificationService(plugin: mockPlugin);

    when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
    when(() => mockPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()).thenReturn(null);
    when(() => mockPlugin.show(any(), any(), any(), any()))
        .thenAnswer((_) async {});
  });

  group('init', () {
    test('initializes plugin', () async {
      await service.init();
      verify(() => mockPlugin.initialize(any())).called(1);
    });
  });

  group('showSmsAlert', () {
    test('uses Scam SMS Detected title for scam verdict', () async {
      await service.showSmsAlert(_alert(verdict: 'scam'));

      verify(() => mockPlugin.show(
            1,
            'Scam SMS Detected',
            'XXXX-5678: Click now to claim',
            any(),
          )).called(1);
    });

    test('uses Suspicious SMS title for suspicious verdict', () async {
      await service.showSmsAlert(_alert(verdict: 'suspicious'));

      verify(() => mockPlugin.show(
            1,
            'Suspicious SMS',
            'XXXX-5678: Click now to claim',
            any(),
          )).called(1);
    });

    test('uses alert id as notification id', () async {
      final alert = SmsAlert(
        id: 42,
        senderMasked: 'XXXX-0000',
        bodyExcerpt: 'test',
        verdict: 'scam',
        detectedAt: DateTime(2026, 5, 5),
        isRead: false,
      );
      await service.showSmsAlert(alert);

      verify(() => mockPlugin.show(42, any(), any(), any())).called(1);
    });

    test('formats body as sender: excerpt', () async {
      final alert = SmsAlert(
        id: 1,
        senderMasked: 'XXXX-1234',
        bodyExcerpt: 'Win a prize',
        verdict: 'suspicious',
        detectedAt: DateTime(2026, 5, 5),
        isRead: false,
      );
      await service.showSmsAlert(alert);

      verify(() => mockPlugin.show(any(), any(), 'XXXX-1234: Win a prize', any()))
          .called(1);
    });
  });
}
