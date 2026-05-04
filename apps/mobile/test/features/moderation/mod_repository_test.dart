import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/moderation/data/mod_api_client.dart';
import 'package:mobile/features/moderation/data/mod_repository_impl.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';

class _MockModApiClient extends Mock implements ModApiClient {}

// Minimal valid item map — all required fields.
Map<String, dynamic> _itemMap({
  String id = 'r1',
  String status = 'pending',
  bool priorityFlag = false,
  String? lastRemarkByAdmin,
}) =>
    {
      'id': id,
      'title': 'Test Report',
      'scamTypeCode': 'PHISH',
      'scamTypeLabelEn': 'Phishing',
      'scamTypeLabelTh': 'ฟิชชิง',
      'submittedAt': '2026-04-20T10:00:00.000Z',
      'status': status,
      'priorityFlag': priorityFlag,
      'evidenceCount': 2,
      'reporterHandle': '@user1',
      'lastRemarkByAdmin': lastRemarkByAdmin,
    };

Map<String, dynamic> _detailMap() => {
      ..._itemMap(),
      'description': 'Full description of the scam.',
      'targetIdentifier': null,
      'targetIdentifierKind': null,
      'evidenceFiles': [
        {
          'id': 'e1',
          'storagePath': 'uploads/e1.jpg',
          'kind': 'image',
          'mimeType': 'image/jpeg',
          'sizeBytes': 204800,
        }
      ],
      'duplicateCount': 0,
      'auditTrail': [
        {
          'adminId': null,
          'action': 'submit',
          'remark': 'Initial submission',
          'createdAt': '2026-04-20T10:00:00.000Z',
        }
      ],
      'aiScore': null,
      'aiConfidence': null,
    };

void main() {
  late _MockModApiClient mockApi;
  late ModRepositoryImpl repo;

  setUp(() {
    mockApi = _MockModApiClient();
    repo = ModRepositoryImpl(mockApi);
  });

  group('ModRepositoryImpl.getQueue', () {
    test('parses ModQueueData correctly', () async {
      when(() => mockApi.fetchQueue()).thenAnswer((_) async => {
            'items': [_itemMap()],
            'pendingCount': 5,
            'flaggedCount': 1,
          });

      final data = await repo.getQueue();

      expect(data.pendingCount, 5);
      expect(data.flaggedCount, 1);
      expect(data.items, hasLength(1));
      expect(data.items.first.id, 'r1');
      expect(data.items.first.scamTypeCode, 'PHISH');
      expect(data.items.first.reporterHandle, '@user1');
      expect(data.items.first.evidenceCount, 2);
      expect(data.items.first.submittedAt, DateTime.utc(2026, 4, 20, 10));
    });

    test('returns empty items list', () async {
      when(() => mockApi.fetchQueue()).thenAnswer((_) async => {
            'items': <dynamic>[],
            'pendingCount': 0,
            'flaggedCount': 0,
          });

      final data = await repo.getQueue();
      expect(data.items, isEmpty);
    });

    test('parses optional lastRemarkByAdmin', () async {
      when(() => mockApi.fetchQueue()).thenAnswer((_) async => {
            'items': [_itemMap(lastRemarkByAdmin: 'Needs more evidence')],
            'pendingCount': 1,
            'flaggedCount': 0,
          });

      final data = await repo.getQueue();
      expect(data.items.first.lastRemarkByAdmin, 'Needs more evidence');
    });
  });

  group('ModQueueItem.isFlagged', () {
    test('true when status is flagged', () {
      final item = ModQueueItem(
        id: 'x', title: 'T', scamTypeCode: 'C', scamTypeLabelEn: '', scamTypeLabelTh: '',
        submittedAt: DateTime.now(), status: 'flagged', priorityFlag: false,
        evidenceCount: 0, reporterHandle: '@u',
      );
      expect(item.isFlagged, true);
    });

    test('false when status is pending', () {
      final item = ModQueueItem(
        id: 'x', title: 'T', scamTypeCode: 'C', scamTypeLabelEn: '', scamTypeLabelTh: '',
        submittedAt: DateTime.now(), status: 'pending', priorityFlag: false,
        evidenceCount: 0, reporterHandle: '@u',
      );
      expect(item.isFlagged, false);
    });
  });

  group('ModRepositoryImpl.getDetail', () {
    test('parses ModReportDetail with all fields', () async {
      when(() => mockApi.fetchDetail(any()))
          .thenAnswer((_) async => {'report': _detailMap()});

      final detail = await repo.getDetail('r1');

      expect(detail.id, 'r1');
      expect(detail.description, 'Full description of the scam.');
      expect(detail.targetIdentifier, isNull);
      expect(detail.aiScore, isNull);
      expect(detail.evidenceFiles, hasLength(1));
      expect(detail.evidenceFiles.first.kind, 'image');
      expect(detail.auditTrail, hasLength(1));
      expect(detail.auditTrail.first.action, 'submit');
      expect(detail.auditTrail.first.adminId, isNull);
    });

    test('isFlagged and isPending computed correctly on detail', () async {
      when(() => mockApi.fetchDetail(any()))
          .thenAnswer((_) async => {'report': {..._detailMap(), 'status': 'flagged'}});

      final detail = await repo.getDetail('r1');
      expect(detail.isFlagged, true);
      expect(detail.isPending, false);
    });
  });

  group('ModRepositoryImpl action delegation', () {
    setUp(() {
      when(() => mockApi.postAction(any(), any(), any()))
          .thenAnswer((_) async {});
    });

    test('approve delegates to postAction with "approve"', () async {
      await repo.approve('r1', 'looks good');
      verify(() => mockApi.postAction('r1', 'approve', 'looks good')).called(1);
    });

    test('reject delegates to postAction with "reject"', () async {
      await repo.reject('r1', 'not enough evidence');
      verify(() => mockApi.postAction('r1', 'reject', 'not enough evidence')).called(1);
    });

    test('flag delegates to postAction with "flag"', () async {
      await repo.flag('r1', 'needs review');
      verify(() => mockApi.postAction('r1', 'flag', 'needs review')).called(1);
    });

    test('unflag delegates to postAction with "unflag"', () async {
      await repo.unflag('r1', '');
      verify(() => mockApi.postAction('r1', 'unflag', '')).called(1);
    });
  });
}
