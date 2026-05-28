import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/data/reports_api.dart';
import 'package:mobile/features/reports/data/reports_repository.dart';
import 'package:mobile/features/reports/domain/my_report.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportsApi extends Mock implements ReportsApi {}

const _reportId = 'rpt-00000001';
const _now = '2026-01-01T00:00:00Z';

Map<String, dynamic> _myReportJson({String status = 'pending'}) => {
      'id': _reportId,
      'title': 'Test phishing report',
      'scamTypeCode': 'phishing_sms',
      'scamTypeLabelEn': 'Phishing SMS',
      'scamTypeLabelTh': 'SMS ฟิชชิ่ง',
      'status': status,
      'createdAt': _now,
      'updatedAt': _now,
      'rejectionRemark': null,
    };

Map<String, dynamic> _editDetailJson() => {
      'id': _reportId,
      'title': 'Test phishing report',
      'description': 'Description.',
      'scamTypeCode': 'phishing_sms',
      'scamTypeLabelEn': 'Phishing SMS',
      'scamTypeLabelTh': 'SMS ฟิชชิ่ง',
      'status': 'pending',
      'targetIdentifier': null,
      'targetIdentifierKind': null,
      'evidenceFiles': [],
    };

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late _MockReportsApi mockApi;
  late ReportsRepository repo;

  setUp(() {
    mockApi = _MockReportsApi();
    repo = ReportsRepository(mockApi);
  });

  group('getMyReports', () {
    test('returns parsed list from api', () async {
      when(() => mockApi.fetchMyReports()).thenAnswer(
        (_) async => [MyReport.fromJson(_myReportJson())],
      );
      final reports = await repo.getMyReports();
      expect(reports, hasLength(1));
      expect(reports.first.id, _reportId);
      verify(() => mockApi.fetchMyReports()).called(1);
    });

    test('returns empty list', () async {
      when(() => mockApi.fetchMyReports()).thenAnswer((_) async => []);
      expect(await repo.getMyReports(), isEmpty);
    });
  });

  group('getMyReportDetail', () {
    test('calls api and parses EditReportDetail', () async {
      when(() => mockApi.fetchMyReportDetail(_reportId))
          .thenAnswer((_) async => _editDetailJson());
      final detail = await repo.getMyReportDetail(_reportId);
      expect(detail.id, _reportId);
      expect(detail.evidenceFiles, isEmpty);
      verify(() => mockApi.fetchMyReportDetail(_reportId)).called(1);
    });
  });

  group('updateReport', () {
    test('delegates to api.updateReport', () async {
      when(() => mockApi.updateReport(
            reportId: any(named: 'reportId'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            scamTypeCode: any(named: 'scamTypeCode'),
            targetIdentifier: any(named: 'targetIdentifier'),
            targetIdentifierKind: any(named: 'targetIdentifierKind'),
            evidenceFiles: any(named: 'evidenceFiles'),
          )).thenAnswer((_) async {});

      await repo.updateReport(
        reportId: _reportId,
        title: 'Updated title',
        description: 'Updated description.',
        scamTypeCode: 'phishing_sms',
      );
      verify(() => mockApi.updateReport(
            reportId: _reportId,
            title: 'Updated title',
            description: 'Updated description.',
            scamTypeCode: 'phishing_sms',
            targetIdentifier: null,
            targetIdentifierKind: null,
            evidenceFiles: [],
          )).called(1);
    });
  });

  group('withdrawReport', () {
    test('delegates to api.withdrawReport', () async {
      when(() => mockApi.withdrawReport(_reportId)).thenAnswer((_) async {});
      await repo.withdrawReport(_reportId);
      verify(() => mockApi.withdrawReport(_reportId)).called(1);
    });
  });

  group('uploadEvidence', () {
    test('delegates to api.uploadEvidence and returns map', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final resultMap = {
        'storagePath': 'path/a.jpg',
        'kind': 'image',
        'mimeType': 'image/jpeg',
        'sizeBytes': 3,
      };
      when(() => mockApi.uploadEvidence(
            bytes: any(named: 'bytes'),
            mimeType: any(named: 'mimeType'),
            filename: any(named: 'filename'),
          )).thenAnswer((_) async => resultMap);

      final result = await repo.uploadEvidence(
        bytes: bytes,
        mimeType: 'image/jpeg',
        filename: 'a.jpg',
      );
      expect(result['kind'], 'image');
      verify(() => mockApi.uploadEvidence(
            bytes: bytes,
            mimeType: 'image/jpeg',
            filename: 'a.jpg',
          )).called(1);
    });
  });
}
