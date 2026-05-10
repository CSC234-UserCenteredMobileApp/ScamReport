import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/search/data/search_api.dart';
import 'package:mobile/features/search/data/search_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchApi extends Mock implements SearchApi {}

void main() {
  late _MockSearchApi mockApi;
  late SearchRepository repo;

  setUp(() {
    mockApi = _MockSearchApi();
    repo = SearchRepository(mockApi);
  });

  group('SearchRepository.searchReports', () {
    test('parses report list from raw API items', () async {
      when(() => mockApi.searchReports(
            q: any(named: 'q'),
            scamTypeCodes: any(named: 'scamTypeCodes'),
            sortBy: any(named: 'sortBy'),
          )).thenAnswer((_) async => [
            {
              'id': 'r1',
              'title': 'Phone scam',
              'excerpt': 'Caller asked for OTP.',
              'scamTypeCode': 'phone',
              'scamTypeLabelEn': 'Phone Scam',
              'scamTypeLabelTh': 'หลอกลวงทางโทรศัพท์',
              'verifiedAt': '2026-05-01T00:00:00.000Z',
              'reportCount': 3,
            },
            {
              'id': 'r2',
              'title': 'Phishing link',
              'excerpt': 'Fake bank site.',
              'scamTypeCode': 'phishing',
              'scamTypeLabelEn': 'Phishing',
              'scamTypeLabelTh': 'ฟิชชิ่ง',
              'verifiedAt': '2026-04-30T00:00:00.000Z',
              'reportCount': 1,
            },
          ]);

      final reports = await repo.searchReports(q: 'phone');

      expect(reports.length, 2);
      expect(reports[0].id, 'r1');
      expect(reports[0].title, 'Phone scam');
      expect(reports[0].scamTypeCode, 'phone');
      expect(reports[0].reportCount, 3);
      expect(reports[0].verifiedAt, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(reports[1].scamTypeLabelTh, 'ฟิชชิ่ง');
    });

    test('returns empty list when API returns no items', () async {
      when(() => mockApi.searchReports(
            q: any(named: 'q'),
            scamTypeCodes: any(named: 'scamTypeCodes'),
            sortBy: any(named: 'sortBy'),
          )).thenAnswer((_) async => []);

      final reports = await repo.searchReports();
      expect(reports, isEmpty);
    });

    test('propagates API errors', () async {
      when(() => mockApi.searchReports(
            q: any(named: 'q'),
            scamTypeCodes: any(named: 'scamTypeCodes'),
            sortBy: any(named: 'sortBy'),
          )).thenThrow(Exception('network error'));

      expect(() => repo.searchReports(q: 'test'), throwsA(isA<Exception>()));
    });
  });

  group('SearchRepository.getScamTypes', () {
    test('parses scam type list from raw API items', () async {
      when(() => mockApi.fetchScamTypes()).thenAnswer((_) async => [
            {
              'code': 'phone',
              'labelEn': 'Phone Scam',
              'labelTh': 'หลอกลวงทางโทรศัพท์',
              'displayOrder': 1,
            },
            {
              'code': 'phishing',
              'labelEn': 'Phishing',
              'labelTh': 'ฟิชชิ่ง',
              'displayOrder': 2,
            },
          ]);

      final types = await repo.getScamTypes();

      expect(types.length, 2);
      expect(types[0].code, 'phone');
      expect(types[0].labelEn, 'Phone Scam');
      expect(types[0].labelTh, 'หลอกลวงทางโทรศัพท์');
      expect(types[0].displayOrder, 1);
      expect(types[1].code, 'phishing');
    });

    test('returns empty list when no scam types', () async {
      when(() => mockApi.fetchScamTypes()).thenAnswer((_) async => []);
      expect(await repo.getScamTypes(), isEmpty);
    });

    test('propagates API errors', () async {
      when(() => mockApi.fetchScamTypes()).thenThrow(Exception('boom'));
      expect(() => repo.getScamTypes(), throwsA(isA<Exception>()));
    });
  });
}
