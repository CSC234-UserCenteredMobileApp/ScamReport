import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/reports/data/reports_api.dart';
import 'package:mobile/features/reports/domain/my_report.dart';
import 'package:mocktail/mocktail.dart';

class _MockUser extends Mock implements User {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _StubClient extends http.BaseClient {
  _StubClient(this._handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

http.StreamedResponse _streamed(int status, String body) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

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
      'description': 'A description of the scam.',
      'scamTypeCode': 'phishing_sms',
      'scamTypeLabelEn': 'Phishing SMS',
      'scamTypeLabelTh': 'SMS ฟิชชิ่ง',
      'status': 'pending',
      'targetIdentifier': null,
      'targetIdentifierKind': null,
      'evidenceFiles': [],
    };

void main() {
  late _MockAuth auth;
  late _MockUser user;

  setUp(() {
    auth = _MockAuth();
    user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'tok-abc');
  });

  ReportsApi _api(Future<http.StreamedResponse> Function(http.BaseRequest) handler) =>
      ReportsApi(_StubClient(handler), auth);

  // ─────────────────────────────────────────────
  // fetchMyReports
  // ─────────────────────────────────────────────

  group('fetchMyReports', () {
    test('returns mapped list on 200', () async {
      final api = _api((_) async => _streamed(
            200,
            jsonEncode({'items': [_myReportJson()]}),
          ));
      final reports = await api.fetchMyReports();
      expect(reports, hasLength(1));
      expect(reports.first.id, _reportId);
      expect(reports.first.status, MyReportStatus.pending);
    });

    test('returns empty list when items is empty', () async {
      final api = _api((_) async => _streamed(200, jsonEncode({'items': []})));
      expect(await api.fetchMyReports(), isEmpty);
    });

    test('throws ReportUnauthorizedException when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(
        () => api.fetchMyReports(),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportUnauthorizedException on 401', () async {
      final api = _api((_) async => _streamed(401, '{"error":"u"}'));
      await expectLater(
        () => api.fetchMyReports(),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws Exception on 5xx', () async {
      final api = _api((_) async => _streamed(500, 'oops'));
      await expectLater(() => api.fetchMyReports(), throwsA(isA<Exception>()));
    });
  });

  // ─────────────────────────────────────────────
  // fetchMyReportDetail
  // ─────────────────────────────────────────────

  group('fetchMyReportDetail', () {
    test('returns map on 200', () async {
      final api = _api((_) async => _streamed(200, jsonEncode(_editDetailJson())));
      final detail = await api.fetchMyReportDetail(_reportId);
      expect(detail['id'], _reportId);
    });

    test('throws when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(
        () => api.fetchMyReportDetail(_reportId),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportUnauthorizedException on 401', () async {
      final api = _api((_) async => _streamed(401, '{}'));
      await expectLater(
        () => api.fetchMyReportDetail(_reportId),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportNotFoundException on 404', () async {
      final api = _api((_) async => _streamed(404, '{}'));
      await expectLater(
        () => api.fetchMyReportDetail(_reportId),
        throwsA(isA<ReportNotFoundException>()),
      );
    });

    test('throws Exception on 5xx', () async {
      final api = _api((_) async => _streamed(500, 'err'));
      await expectLater(
        () => api.fetchMyReportDetail(_reportId),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // fetchReportDetail (public, no auth)
  // ─────────────────────────────────────────────

  group('fetchReportDetail', () {
    test('returns map on 200 without auth header', () async {
      http.BaseRequest? captured;
      final api = _api((req) async {
        captured = req;
        return _streamed(200, jsonEncode({'id': _reportId}));
      });
      final result = await api.fetchReportDetail(_reportId);
      expect(result['id'], _reportId);
      expect(captured?.headers.containsKey('Authorization'), isFalse);
    });

    test('throws ReportNotFoundException on 404', () async {
      final api = _api((_) async => _streamed(404, '{}'));
      await expectLater(
        () => api.fetchReportDetail(_reportId),
        throwsA(isA<ReportNotFoundException>()),
      );
    });

    test('throws Exception on 5xx', () async {
      final api = _api((_) async => _streamed(500, 'err'));
      await expectLater(
        () => api.fetchReportDetail(_reportId),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // updateReport
  // ─────────────────────────────────────────────

  group('updateReport', () {
    const _body = {
      'title': 'Updated title that is long enough',
      'description': 'Updated description that is also long enough.',
      'scamTypeCode': 'phishing_sms',
    };

    test('completes on 200', () async {
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(
        api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        completes,
      );
    });

    test('throws when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(
        () => api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportUnauthorizedException on 401', () async {
      final api = _api((_) async => _streamed(401, '{}'));
      await expectLater(
        () => api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportValidationException on 400', () async {
      final api = _api((_) async => _streamed(400, '{"error":"bad input"}'));
      await expectLater(
        () => api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        throwsA(isA<ReportValidationException>()),
      );
    });

    test('throws ReportValidationException on 409', () async {
      final api = _api((_) async => _streamed(409, '{"error":"not editable"}'));
      await expectLater(
        () => api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        throwsA(isA<ReportValidationException>()),
      );
    });

    test('throws ReportNotFoundException on 404', () async {
      final api = _api((_) async => _streamed(404, '{}'));
      await expectLater(
        () => api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        throwsA(isA<ReportNotFoundException>()),
      );
    });

    test('throws Exception on 5xx', () async {
      final api = _api((_) async => _streamed(500, 'err'));
      await expectLater(
        () => api.updateReport(
          reportId: _reportId,
          title: _body['title']!,
          description: _body['description']!,
          scamTypeCode: _body['scamTypeCode']!,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('includes targetIdentifier in body when non-empty', () async {
      String? sentBody;
      final api = _api((req) async {
        if (req is http.Request) sentBody = req.body;
        return _streamed(200, '{}');
      });
      await api.updateReport(
        reportId: _reportId,
        title: _body['title']!,
        description: _body['description']!,
        scamTypeCode: _body['scamTypeCode']!,
        targetIdentifier: '+66812345678',
        targetIdentifierKind: 'phone',
      );
      final json = jsonDecode(sentBody!) as Map<String, dynamic>;
      expect(json['targetIdentifier'], '+66812345678');
      expect(json['targetIdentifierKind'], 'phone');
    });

    test('omits targetIdentifier when empty string', () async {
      String? sentBody;
      final api = _api((req) async {
        if (req is http.Request) sentBody = req.body;
        return _streamed(200, '{}');
      });
      await api.updateReport(
        reportId: _reportId,
        title: _body['title']!,
        description: _body['description']!,
        scamTypeCode: _body['scamTypeCode']!,
        targetIdentifier: '',
      );
      final json = jsonDecode(sentBody!) as Map<String, dynamic>;
      expect(json.containsKey('targetIdentifier'), isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // withdrawReport
  // ─────────────────────────────────────────────

  group('withdrawReport', () {
    test('completes on 200', () async {
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(api.withdrawReport(_reportId), completes);
    });

    test('throws when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(
        () => api.withdrawReport(_reportId),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportUnauthorizedException on 401', () async {
      final api = _api((_) async => _streamed(401, '{}'));
      await expectLater(
        () => api.withdrawReport(_reportId),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportValidationException on 409', () async {
      final api = _api((_) async => _streamed(409, '{"error":"verified"}'));
      await expectLater(
        () => api.withdrawReport(_reportId),
        throwsA(isA<ReportValidationException>()),
      );
    });

    test('throws ReportNotFoundException on 404', () async {
      final api = _api((_) async => _streamed(404, '{}'));
      await expectLater(
        () => api.withdrawReport(_reportId),
        throwsA(isA<ReportNotFoundException>()),
      );
    });

    test('throws Exception on 5xx', () async {
      final api = _api((_) async => _streamed(500, 'err'));
      await expectLater(
        () => api.withdrawReport(_reportId),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // uploadEvidence
  // ─────────────────────────────────────────────

  group('uploadEvidence', () {
    test('sends multipart and returns metadata map on 200', () async {
      String? capturedPath;
      final api = _api((req) async {
        capturedPath = req.url.path;
        return _streamed(
          200,
          jsonEncode({
            'storagePath': 'reporter-1/abc.jpg',
            'kind': 'image',
            'mimeType': 'image/jpeg',
            'sizeBytes': 4,
          }),
        );
      });
      final meta = await api.uploadEvidence(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'image/jpeg',
        filename: 'abc.jpg',
      );
      expect(capturedPath, '/reports/evidence');
      expect(meta['kind'], 'image');
      expect(meta['storagePath'], 'reporter-1/abc.jpg');
    });

    test('throws when no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final api = _api((_) async => _streamed(200, '{}'));
      await expectLater(
        () => api.uploadEvidence(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportUnauthorizedException on 401', () async {
      final api = _api((_) async => _streamed(401, '{}'));
      await expectLater(
        () => api.uploadEvidence(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
        throwsA(isA<ReportUnauthorizedException>()),
      );
    });

    test('throws ReportValidationException on 413', () async {
      final api = _api((_) async => _streamed(413, '{"error":"too big"}'));
      await expectLater(
        () => api.uploadEvidence(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
        throwsA(isA<ReportValidationException>()),
      );
    });

    test('throws ReportValidationException on 415', () async {
      final api = _api((_) async => _streamed(415, '{"error":"bad mime"}'));
      await expectLater(
        () => api.uploadEvidence(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
        throwsA(isA<ReportValidationException>()),
      );
    });

    test('throws Exception on 5xx', () async {
      final api = _api((_) async => _streamed(500, 'err'));
      await expectLater(
        () => api.uploadEvidence(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/jpeg',
          filename: 'a.jpg',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // ReportValidationException.toString
  // ─────────────────────────────────────────────

  test('ReportValidationException.toString returns message', () {
    const ex = ReportValidationException('bad input');
    expect(ex.toString(), 'bad input');
  });

  // ─────────────────────────────────────────────
  // _extractError fallback — non-JSON body
  // ─────────────────────────────────────────────

  test('extractError falls back to reasonPhrase on non-JSON body', () async {
    final api = _api((_) async => http.StreamedResponse(
          Stream.value(utf8.encode('not json')),
          400,
          reasonPhrase: 'Bad Request',
          headers: {'content-type': 'text/plain'},
        ));
    await expectLater(
      () => api.updateReport(
        reportId: _reportId,
        title: 'Long enough title here',
        description: 'Long enough description here too.',
        scamTypeCode: 'phishing_sms',
      ),
      throwsA(
        isA<ReportValidationException>().having(
          (e) => e.message,
          'message',
          'Bad Request',
        ),
      ),
    );
  });
}
