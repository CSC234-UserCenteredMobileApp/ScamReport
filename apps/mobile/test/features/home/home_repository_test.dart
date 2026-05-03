import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/home/data/home_api.dart';
import 'package:mobile/features/home/data/home_repository.dart';
import 'package:mobile/features/home/domain/recent_alert.dart';

class MockHomeApi extends Mock implements HomeApi {}

void main() {
  late MockHomeApi mockApi;
  late HomeRepository repo;

  setUp(() {
    mockApi = MockHomeApi();
    repo = HomeRepository(mockApi);
  });

  group('getStats', () {
    test('parses stats from API response', () async {
      when(() => mockApi.fetchStats()).thenAnswer((_) async => {
            'data': {
              'verifiedTotal': 100,
              'newThisWeek': 10,
              'topScamTypeLabelEn': 'Phishing',
              'topScamTypeLabelTh': 'ฟิชชิ่ง',
            },
          });

      final stats = await repo.getStats();
      expect(stats.verifiedTotal, 100);
      expect(stats.newThisWeek, 10);
      expect(stats.topScamTypeLabelEn, 'Phishing');
      expect(stats.topScamTypeLabelTh, 'ฟิชชิ่ง');
    });
  });

  group('getRecentAlerts', () {
    test('parses fraud_alert category', () async {
      when(() => mockApi.fetchRecentAlerts()).thenAnswer((_) async => [
            {
              'id': 'a1',
              'title': 'Alert 1',
              'category': 'fraud_alert',
              'publishedAt': '2026-04-20T00:00:00.000Z',
            },
          ]);

      final alerts = await repo.getRecentAlerts();
      expect(alerts.length, 1);
      expect(alerts[0].category, AlertCategory.fraudAlert);
      expect(alerts[0].id, 'a1');
    });

    test('parses tips category', () async {
      when(() => mockApi.fetchRecentAlerts()).thenAnswer((_) async => [
            {
              'id': 'a2',
              'title': 'Tips Alert',
              'category': 'tips',
              'publishedAt': '2026-04-19T00:00:00.000Z',
            },
          ]);

      final alerts = await repo.getRecentAlerts();
      expect(alerts[0].category, AlertCategory.tips);
    });

    test('parses platform_update category', () async {
      when(() => mockApi.fetchRecentAlerts()).thenAnswer((_) async => [
            {
              'id': 'a3',
              'title': 'Update Alert',
              'category': 'platform_update',
              'publishedAt': '2026-04-18T00:00:00.000Z',
            },
          ]);

      final alerts = await repo.getRecentAlerts();
      expect(alerts[0].category, AlertCategory.platformUpdate);
    });

    test('throws on unknown category', () async {
      when(() => mockApi.fetchRecentAlerts()).thenAnswer((_) async => [
            {
              'id': 'a4',
              'title': 'Unknown',
              'category': 'unknown_category',
              'publishedAt': '2026-04-18T00:00:00.000Z',
            },
          ]);

      expect(
        () => repo.getRecentAlerts(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('getRecentReports', () {
    test('parses report data correctly', () async {
      when(() => mockApi.fetchRecentReports()).thenAnswer((_) async => [
            {
              'id': 'r1',
              'title': 'Test Report',
              'excerpt': 'Test excerpt.',
              'scamTypeCode': 'phishing_sms',
              'scamTypeLabelEn': 'Phishing SMS',
              'scamTypeLabelTh': 'ข้อความหลอกลวง',
              'verifiedAt': '2026-04-20T00:00:00.000Z',
              'reportCount': 14,
            },
          ]);

      final reports = await repo.getRecentReports();
      expect(reports.length, 1);
      expect(reports[0].id, 'r1');
      expect(reports[0].title, 'Test Report');
      expect(reports[0].excerpt, 'Test excerpt.');
      expect(reports[0].scamTypeCode, 'phishing_sms');
      expect(reports[0].scamTypeLabelEn, 'Phishing SMS');
      expect(reports[0].scamTypeLabelTh, 'ข้อความหลอกลวง');
      expect(reports[0].reportCount, 14);
    });

    test('returns empty list when API returns no items', () async {
      when(() => mockApi.fetchRecentReports())
          .thenAnswer((_) async => <dynamic>[]);

      final reports = await repo.getRecentReports();
      expect(reports, isEmpty);
    });
  });
}
