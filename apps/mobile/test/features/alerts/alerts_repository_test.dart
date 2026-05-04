import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/alerts/data/alerts_api_client.dart';
import 'package:mobile/features/alerts/data/alerts_repository_impl.dart';
import 'package:mobile/features/home/domain/recent_alert.dart';

Map<String, dynamic> _alertJson({
  String id = 'a1',
  String category = 'fraud_alert',
  String? body,
  String? slug,
}) =>
    {
      'id': id,
      'title': 'Test Alert',
      'excerpt': 'Test excerpt',
      if (body != null) 'body': body,
      if (slug != null) 'slug': slug,
      'category': category,
      'publishedAt': '2026-04-23T00:00:00.000Z',
    };

http.Client _listClient(List<Map<String, dynamic>> items) => MockClient(
      (_) async => http.Response(
        jsonEncode({'items': items}),
        200,
      ),
    );

http.Client _singleClient(Map<String, dynamic> item) => MockClient(
      (_) async => http.Response(jsonEncode({'item': item}), 200),
    );

http.Client _errorClient(int status) =>
    MockClient((_) async => http.Response('error', status));

AlertsRepositoryImpl _repo(http.Client client) =>
    AlertsRepositoryImpl(AlertsApiClient(client));

void main() {
  group('AlertsRepositoryImpl.listAlerts', () {
    test('parses alert list correctly', () async {
      final repo = _repo(_listClient([_alertJson(body: 'Full body', slug: 'test-slug')]));
      final alerts = await repo.listAlerts();

      expect(alerts, hasLength(1));
      expect(alerts.first.id, 'a1');
      expect(alerts.first.title, 'Test Alert');
      expect(alerts.first.excerpt, 'Test excerpt');
      expect(alerts.first.body, 'Full body');
      expect(alerts.first.slug, 'test-slug');
      expect(alerts.first.category, AlertCategory.fraudAlert);
      expect(alerts.first.publishedAt, DateTime.utc(2026, 4, 23));
    });

    test('returns empty list when items is empty', () async {
      final repo = _repo(_listClient([]));
      expect(await repo.listAlerts(), isEmpty);
    });

    test('throws on 5xx response', () async {
      final repo = _repo(_errorClient(500));
      expect(repo.listAlerts(), throwsA(isA<Exception>()));
    });

    test('optional body defaults to empty string when absent', () async {
      final repo = _repo(_listClient([_alertJson()]));
      final alerts = await repo.listAlerts();
      expect(alerts.first.body, '');
    });

    test('optional slug defaults to empty string when absent', () async {
      final repo = _repo(_listClient([_alertJson()]));
      final alerts = await repo.listAlerts();
      expect(alerts.first.slug, '');
    });
  });

  group('AlertsRepositoryImpl.getAlert', () {
    test('parses single alert', () async {
      final repo = _repo(_singleClient(_alertJson(category: 'tips')));
      final alert = await repo.getAlert('a1');

      expect(alert.id, 'a1');
      expect(alert.category, AlertCategory.tips);
    });

    test('throws with not-found message on 404', () async {
      final repo = _repo(_errorClient(404));
      expect(
        repo.getAlert('missing'),
        throwsA(
          predicate((e) => e.toString().contains('not found')),
        ),
      );
    });

    test('throws on other non-2xx response', () async {
      final repo = _repo(_errorClient(403));
      expect(repo.getAlert('x'), throwsA(isA<Exception>()));
    });
  });

  group('AlertsRepositoryImpl._parseCategory', () {
    test('fraud_alert → fraudAlert', () async {
      final repo = _repo(_listClient([_alertJson(category: 'fraud_alert')]));
      final alerts = await repo.listAlerts();
      expect(alerts.first.category, AlertCategory.fraudAlert);
    });

    test('tips → tips', () async {
      final repo = _repo(_listClient([_alertJson(category: 'tips')]));
      final alerts = await repo.listAlerts();
      expect(alerts.first.category, AlertCategory.tips);
    });

    test('platform_update → platformUpdate', () async {
      final repo = _repo(_listClient([_alertJson(category: 'platform_update')]));
      final alerts = await repo.listAlerts();
      expect(alerts.first.category, AlertCategory.platformUpdate);
    });

    test('unknown category falls back to platformUpdate', () async {
      final repo = _repo(_listClient([_alertJson(category: 'new_unknown')]));
      final alerts = await repo.listAlerts();
      expect(alerts.first.category, AlertCategory.platformUpdate);
    });
  });
}
