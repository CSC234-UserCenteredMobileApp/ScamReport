import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/my_report.dart';

Map<String, dynamic> _baseJson({
  String status = 'pending',
  String? rejectionRemark,
}) =>
    {
      'id': 'r-001',
      'title': 'Phishing SMS report',
      'scamTypeCode': 'phishing_sms',
      'scamTypeLabelEn': 'Phishing SMS',
      'scamTypeLabelTh': 'SMS ฟิชชิ่ง',
      'status': status,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-02T00:00:00Z',
      if (rejectionRemark != null) 'rejectionRemark': rejectionRemark,
    };

void main() {
  group('MyReport.fromJson', () {
    test('parses required fields correctly', () {
      final report = MyReport.fromJson(_baseJson());
      expect(report.id, 'r-001');
      expect(report.title, 'Phishing SMS report');
      expect(report.scamTypeCode, 'phishing_sms');
      expect(report.scamTypeLabelEn, 'Phishing SMS');
      expect(report.scamTypeLabelTh, 'SMS ฟิชชิ่ง');
      expect(report.createdAt, DateTime.utc(2026, 1, 1));
      expect(report.updatedAt, DateTime.utc(2026, 1, 2));
    });

    test('rejectionRemark is null when absent', () {
      final report = MyReport.fromJson(_baseJson());
      expect(report.rejectionRemark, isNull);
    });

    test('rejectionRemark is populated when present', () {
      final report = MyReport.fromJson(
        _baseJson(rejectionRemark: 'Insufficient evidence'),
      );
      expect(report.rejectionRemark, 'Insufficient evidence');
    });

    group('status parsing', () {
      test('pending status', () {
        final report = MyReport.fromJson(_baseJson(status: 'pending'));
        expect(report.status, MyReportStatus.pending);
      });

      test('verified status', () {
        final report = MyReport.fromJson(_baseJson(status: 'verified'));
        expect(report.status, MyReportStatus.verified);
      });

      test('rejected status', () {
        final report = MyReport.fromJson(_baseJson(status: 'rejected'));
        expect(report.status, MyReportStatus.rejected);
      });

      test('withdrawn status', () {
        final report = MyReport.fromJson(_baseJson(status: 'withdrawn'));
        expect(report.status, MyReportStatus.withdrawn);
      });

      test('flagged maps to pending (FR-6.1)', () {
        final report = MyReport.fromJson(_baseJson(status: 'flagged'));
        expect(report.status, MyReportStatus.pending);
      });

      test('unknown status defaults to pending', () {
        final report = MyReport.fromJson(_baseJson(status: 'unknown_value'));
        expect(report.status, MyReportStatus.pending);
      });
    });
  });
}
