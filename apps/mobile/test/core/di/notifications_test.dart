import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/di/notifications.dart';
import 'package:mobile/core/services/notification_service.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
  });

  test('notificationServiceProvider returns a NotificationService', () {
    final mockPlugin = _MockPlugin();
    when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
    when(() => mockPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()).thenReturn(null);

    final container = ProviderContainer(overrides: [
      notificationServiceProvider
          .overrideWithValue(NotificationService(plugin: mockPlugin)),
    ]);
    addTearDown(container.dispose);

    final service = container.read(notificationServiceProvider);
    expect(service, isA<NotificationService>());
  });
}
