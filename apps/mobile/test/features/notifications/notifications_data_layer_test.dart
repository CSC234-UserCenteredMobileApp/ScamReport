// Data-layer coverage for notifications: NotificationsApiClient (HTTP + auth
// header + error mapping) and NotificationsRepositoryImpl (wire mapping).
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/notifications/data/notifications_api_client.dart';
import 'package:mobile/features/notifications/data/notifications_repository_impl.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockNotificationsApiClient extends Mock
    implements NotificationsApiClient {}

void main() {
  group('NotificationsApiClient', () {
    late MockFirebaseAuth auth;
    late MockUser user;

    setUp(() {
      auth = MockFirebaseAuth();
      user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'tok-123');
    });

    NotificationsApiClient clientWith(MockClientHandler handler) =>
        NotificationsApiClient(MockClient(handler), auth);

    test('throws StateError when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = clientWith((_) async => http.Response('{}', 200));
      expect(api.fetchInbox, throwsStateError);
    });

    test('throws StateError when the ID token is null', () async {
      when(() => user.getIdToken()).thenAnswer((_) async => null);
      final api = clientWith((_) async => http.Response('{}', 200));
      expect(api.fetchInbox, throwsStateError);
    });

    test('fetchInbox GETs /me/notifications with a bearer token', () async {
      late http.Request seen;
      final api = clientWith((request) async {
        seen = request;
        return http.Response(
          jsonEncode({'items': <Object>[], 'unreadCount': 0}),
          200,
        );
      });

      final raw = await api.fetchInbox();

      expect(seen.method, 'GET');
      expect(seen.url.path, '/me/notifications');
      expect(seen.headers['Authorization'], 'Bearer tok-123');
      expect(raw['unreadCount'], 0);
    });

    test('markRead POSTs the ids and returns the body', () async {
      late http.Request seen;
      final api = clientWith((request) async {
        seen = request;
        return http.Response(jsonEncode({'unreadCount': 1}), 200);
      });

      final raw = await api.markRead(['n1', 'n2']);

      expect(seen.method, 'POST');
      expect(seen.url.path, '/me/notifications/read');
      expect(jsonDecode(seen.body), {
        'ids': ['n1', 'n2'],
      });
      expect(raw['unreadCount'], 1);
    });

    test('registerToken includes appVersion only when provided', () async {
      final bodies = <Map<String, dynamic>>[];
      final api = clientWith((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('', 204);
      });

      await api.registerToken(
          fcmToken: 't1', platform: 'android', appVersion: '1.0');
      await api.registerToken(fcmToken: 't1', platform: 'android');

      expect(bodies[0]['appVersion'], '1.0');
      expect(bodies[1].containsKey('appVersion'), isFalse);
    });

    test('unregisterToken DELETEs the encoded token; 404 is success', () async {
      late http.Request seen;
      final api = clientWith((request) async {
        seen = request;
        return http.Response('gone', 404);
      });

      await api.unregisterToken('tok/with:odd chars');

      expect(seen.method, 'DELETE');
      expect(seen.url.path,
          '/me/fcm-tokens/${Uri.encodeComponent('tok/with:odd chars')}');
    });

    test('non-2xx maps to NotificationsApiFailure with the json error message',
        () async {
      final api = clientWith(
        (_) async => http.Response(jsonEncode({'error': 'nope'}), 401),
      );

      try {
        await api.fetchInbox();
        fail('expected NotificationsApiFailure');
      } on NotificationsApiFailure catch (e) {
        expect(e.statusCode, 401);
        expect(e.action, 'inbox');
        expect(e.serverMessage, 'nope');
        expect(e.toString(), contains('inbox'));
      }
    });

    test('non-json error bodies fall back to the raw text, truncated at 280',
        () async {
      final longBody = 'x' * 300;
      final api = clientWith((_) async => http.Response(longBody, 500));

      try {
        await api.markRead(const []);
        fail('expected NotificationsApiFailure');
      } on NotificationsApiFailure catch (e) {
        expect(e.serverMessage.length, 281); // 280 + ellipsis
        expect(e.serverMessage.endsWith('…'), isTrue);
      }
    });

    test('empty error body maps to an empty message', () async {
      final api = clientWith((_) async => http.Response('', 500));
      try {
        await api.unregisterToken('t');
        fail('expected NotificationsApiFailure');
      } on NotificationsApiFailure catch (e) {
        expect(e.serverMessage, '');
        expect(e.action, 'unregister-token');
      }
    });
  });

  group('NotificationsRepositoryImpl', () {
    late MockNotificationsApiClient api;
    late NotificationsRepositoryImpl repo;

    setUp(() {
      api = MockNotificationsApiClient();
      repo = NotificationsRepositoryImpl(api);
    });

    test('listInbox maps items, kinds, and unreadCount', () async {
      when(() => api.fetchInbox()).thenAnswer((_) async => {
            'items': [
              {
                'id': 'n1',
                'kind': 'report_verified',
                'title': 'Verified',
                'body': 'Your report is live',
                'reportId': 'r1',
                'isRead': false,
                'createdAt': '2026-06-01T10:00:00.000Z',
              },
              {
                'id': 'n2',
                'kind': 'definitely-not-a-kind',
                'title': 'Strange',
                'body': '',
                'reportId': null,
                'isRead': true,
                'createdAt': '2026-06-02T10:00:00.000Z',
              },
            ],
            'unreadCount': 1,
          });

      final data = await repo.listInbox();

      expect(data.unreadCount, 1);
      expect(data.items, hasLength(2));
      expect(data.items[0].reportId, 'r1');
      expect(data.items[0].isRead, isFalse);
      expect(data.items[1].kind, NotificationKind.unknown);
      expect(data.items[1].reportId, isNull);
    });

    test('markRead delegates and returns the unread count', () async {
      when(() => api.markRead(['n1']))
          .thenAnswer((_) async => {'unreadCount': 4});
      expect(await repo.markRead(['n1']), 4);
    });

    test('registerDevice / unregisterDevice delegate to the client', () async {
      when(() => api.registerToken(
            fcmToken: 't1',
            platform: 'android',
            appVersion: null,
          )).thenAnswer((_) async {});
      when(() => api.unregisterToken('t1')).thenAnswer((_) async {});

      await repo.registerDevice(fcmToken: 't1', platform: 'android');
      await repo.unregisterDevice('t1');

      verify(() => api.registerToken(
            fcmToken: 't1',
            platform: 'android',
            appVersion: null,
          )).called(1);
      verify(() => api.unregisterToken('t1')).called(1);
    });

    test('propagates NotificationsApiFailure from the client', () async {
      when(() => api.fetchInbox()).thenThrow(NotificationsApiFailure(
        statusCode: 500,
        serverMessage: 'boom',
        action: 'inbox',
      ));
      expect(repo.listInbox, throwsA(isA<NotificationsApiFailure>()));
    });
  });
}
