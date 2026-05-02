import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feed/data/feed_api.dart';
import 'package:mobile/features/feed/data/feed_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedApi extends Mock implements FeedApi {}

void main() {
  late MockFeedApi mockApi;
  late FeedRepository repo;

  setUp(() {
    mockApi = MockFeedApi();
    repo = FeedRepository(mockApi);
  });

  group('FeedRepository.getReports', () {
    test('parses report list from API response', () async {
      when(() => mockApi.fetchReports()).thenAnswer((_) async => [
            {
              'id': 'r1',
              'title': 'Fake Kerry parcel SMS',
              'excerpt': 'Phishing link in parcel SMS.',
              'scamTypeCode': 'phishing_sms',
              'scamTypeLabelEn': 'Phishing SMS',
              'scamTypeLabelTh': 'SMS หลอกลวง',
              'verifiedAt': '2026-05-01T00:00:00.000Z',
              'reportCount': 3,
            },
            {
              'id': 'r2',
              'title': 'Fake Lazada QR',
              'excerpt': 'QR redirects to mule account.',
              'scamTypeCode': 'fake_qr',
              'scamTypeLabelEn': 'Fake QR code',
              'scamTypeLabelTh': 'QR Code ปลอม',
              'verifiedAt': '2026-04-29T00:00:00.000Z',
              'reportCount': 1,
            },
          ]);

      final reports = await repo.getReports();

      expect(reports.length, 2);
      expect(reports[0].id, 'r1');
      expect(reports[0].title, 'Fake Kerry parcel SMS');
      expect(reports[0].scamTypeCode, 'phishing_sms');
      expect(reports[0].reportCount, 3);
      expect(reports[0].verifiedAt, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(reports[1].scamTypeCode, 'fake_qr');
      expect(reports[1].scamTypeLabelTh, 'QR Code ปลอม');
    });

    test('returns empty list when API returns no items', () async {
      when(() => mockApi.fetchReports()).thenAnswer((_) async => <dynamic>[]);
      final reports = await repo.getReports();
      expect(reports, isEmpty);
    });

    test('propagates API errors', () async {
      when(() => mockApi.fetchReports()).thenThrow(Exception('boom'));
      expect(() => repo.getReports(), throwsA(isA<Exception>()));
    });
  });
}
