import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/edit_report_detail.dart';

Map<String, dynamic> _evidenceFileJson({
  String id = 'ef-1',
  String storagePath = 'uploads/ef-1.jpg',
  String? signedUrl = 'https://signed.example/ef-1.jpg',
  String kind = 'image',
  String mimeType = 'image/jpeg',
  int sizeBytes = 20480,
}) =>
    {
      'id': id,
      'storagePath': storagePath,
      'signedUrl': signedUrl,
      'kind': kind,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    };

Map<String, dynamic> _detailJson({
  List<Map<String, dynamic>> evidenceFiles = const [],
  String? targetIdentifier,
  String? targetIdentifierKind,
}) =>
    {
      'id': 'rpt-1',
      'title': 'Test phishing report',
      'description': 'Description of the phishing attempt.',
      'scamTypeCode': 'phishing_sms',
      'scamTypeLabelEn': 'Phishing SMS',
      'scamTypeLabelTh': 'SMS ฟิชชิ่ง',
      'status': 'pending',
      'targetIdentifier': targetIdentifier,
      'targetIdentifierKind': targetIdentifierKind,
      'evidenceFiles': evidenceFiles,
    };

void main() {
  group('EditReportDetail.fromJson', () {
    test('parses required fields', () {
      final detail = EditReportDetail.fromJson(_detailJson());
      expect(detail.id, 'rpt-1');
      expect(detail.title, 'Test phishing report');
      expect(detail.description, 'Description of the phishing attempt.');
      expect(detail.scamTypeCode, 'phishing_sms');
      expect(detail.scamTypeLabelEn, 'Phishing SMS');
      expect(detail.scamTypeLabelTh, 'SMS ฟิชชิ่ง');
      expect(detail.status, 'pending');
      expect(detail.evidenceFiles, isEmpty);
    });

    test('optional fields are null when absent', () {
      final detail = EditReportDetail.fromJson(_detailJson());
      expect(detail.targetIdentifier, isNull);
      expect(detail.targetIdentifierKind, isNull);
    });

    test('parses targetIdentifier and kind', () {
      final detail = EditReportDetail.fromJson(_detailJson(
        targetIdentifier: 'kerry-th.net',
        targetIdentifierKind: 'url',
      ));
      expect(detail.targetIdentifier, 'kerry-th.net');
      expect(detail.targetIdentifierKind, 'url');
    });

    test('parses evidenceFiles list', () {
      final detail = EditReportDetail.fromJson(_detailJson(
        evidenceFiles: [_evidenceFileJson()],
      ));
      expect(detail.evidenceFiles, hasLength(1));
      final f = detail.evidenceFiles.first;
      expect(f.id, 'ef-1');
      expect(f.storagePath, 'uploads/ef-1.jpg');
      expect(f.signedUrl, 'https://signed.example/ef-1.jpg');
      expect(f.kind, 'image');
      expect(f.mimeType, 'image/jpeg');
      expect(f.sizeBytes, 20480);
    });

    test('evidence signedUrl can be null', () {
      final detail = EditReportDetail.fromJson(_detailJson(
        evidenceFiles: [_evidenceFileJson(signedUrl: null)],
      ));
      expect(detail.evidenceFiles.first.signedUrl, isNull);
    });

    test('parses sizeBytes as int from num', () {
      final detail = EditReportDetail.fromJson(_detailJson(
        evidenceFiles: [_evidenceFileJson(sizeBytes: 4096)],
      ));
      expect(detail.evidenceFiles.first.sizeBytes, 4096);
    });
  });

  group('ExistingFile.fromEvidence', () {
    test('maps all fields from ExistingEvidenceFile', () {
      const evidence = ExistingEvidenceFile(
        id: 'ef-2',
        storagePath: 'uploads/ef-2.pdf',
        signedUrl: 'https://signed.example/ef-2.pdf',
        kind: 'pdf',
        mimeType: 'application/pdf',
        sizeBytes: 512000,
      );
      final existing = ExistingFile.fromEvidence(evidence);
      expect(existing.id, 'ef-2');
      expect(existing.storagePath, 'uploads/ef-2.pdf');
      expect(existing.signedUrl, 'https://signed.example/ef-2.pdf');
      expect(existing.kind, 'pdf');
      expect(existing.mimeType, 'application/pdf');
      expect(existing.sizeBytes, 512000);
    });

    test('signedUrl null is preserved', () {
      const evidence = ExistingEvidenceFile(
        id: 'ef-3',
        storagePath: 'uploads/ef-3.jpg',
        kind: 'image',
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
      );
      final existing = ExistingFile.fromEvidence(evidence);
      expect(existing.signedUrl, isNull);
    });
  });

  group('NewFile', () {
    test('stores bytes, mimeType, filename', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final file = NewFile(
        bytes: bytes,
        mimeType: 'image/png',
        filename: 'screenshot.png',
      );
      expect(file.bytes, bytes);
      expect(file.mimeType, 'image/png');
      expect(file.filename, 'screenshot.png');
    });
  });

  group('EditStagedFile sealed class', () {
    test('ExistingFile is an EditStagedFile', () {
      const f = ExistingFile(
        id: 'x',
        storagePath: 'p',
        kind: 'image',
        mimeType: 'image/jpeg',
        sizeBytes: 0,
      );
      expect(f, isA<EditStagedFile>());
    });

    test('NewFile is an EditStagedFile', () {
      final f = NewFile(
        bytes: Uint8List(0),
        mimeType: 'image/jpeg',
        filename: 'a.jpg',
      );
      expect(f, isA<EditStagedFile>());
    });
  });
}
