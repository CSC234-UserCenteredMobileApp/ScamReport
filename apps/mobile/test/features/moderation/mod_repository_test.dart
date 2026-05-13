import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/features/moderation/data/mod_api_client.dart';
import 'package:mobile/features/moderation/data/mod_repository_impl.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';

class _MockModApiClient extends Mock implements ModApiClient {}

// Minimal valid item map. The mapper must not read reporter identity even if
// a misbehaving server bug regressed and included `reporterHandle`/
// `reporterId`. PRD v1.2 FR-7.4 + FR-7.8.
Map<String, dynamic> _itemMap({
  String id = 'r1',
  String status = 'pending',
  bool priorityFlag = false,
  String? lastRemarkByAdmin,
  bool injectReporterFields = false,
  int? aiScore,
  String? aiConfidence,
}) {
  final base = <String, dynamic>{
    'id': id,
    'title': 'Test Report',
    'scamTypeCode': 'phishing_sms',
    'scamTypeLabelEn': 'Phishing SMS',
    'scamTypeLabelTh': 'ฟิชชิง SMS',
    'submittedAt': '2026-04-20T10:00:00.000Z',
    'status': status,
    'priorityFlag': priorityFlag,
    'evidenceCount': 2,
    'lastRemarkByAdmin': lastRemarkByAdmin,
    'aiScore': aiScore,
    'aiConfidence': aiConfidence,
  };
  if (injectReporterFields) {
    base['reporterHandle'] = '@SHOULD_BE_DROPPED';
    base['reporterId'] = '00000000-0000-0000-0000-000000000000';
  }
  return base;
}

Map<String, dynamic> _detailMap({bool injectReporterFields = false}) {
  final detail = <String, dynamic>{
    ..._itemMap(injectReporterFields: injectReporterFields),
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
  return detail;
}

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
      expect(data.items.first.scamTypeCode, 'phishing_sms');
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

    test('mapper does not throw when server includes reporter fields', () async {
      when(() => mockApi.fetchQueue()).thenAnswer((_) async => {
            'items': [_itemMap(injectReporterFields: true)],
            'pendingCount': 1,
            'flaggedCount': 0,
          });

      // No reporterHandle/reporterId getter exists on ModQueueItem; the mapper
      // must silently drop those keys without throwing.
      final data = await repo.getQueue();
      expect(data.items, hasLength(1));
    });

    test('parses persisted aiScore + aiConfidence from queue item', () async {
      when(() => mockApi.fetchQueue()).thenAnswer((_) async => {
            'items': [_itemMap(aiScore: 87, aiConfidence: 'high')],
            'pendingCount': 1,
            'flaggedCount': 0,
          });

      final data = await repo.getQueue();
      expect(data.items.first.aiScore, 87);
      expect(data.items.first.aiConfidence, 'high');
    });

    test('tolerates null ai fields on legacy rows', () async {
      when(() => mockApi.fetchQueue()).thenAnswer((_) async => {
            'items': [_itemMap()],
            'pendingCount': 1,
            'flaggedCount': 0,
          });

      final data = await repo.getQueue();
      expect(data.items.first.aiScore, isNull);
      expect(data.items.first.aiConfidence, isNull);
    });
  });

  group('ModQueueItem.isFlagged', () {
    test('true when status is flagged', () {
      final item = ModQueueItem(
        id: 'x',
        title: 'T',
        scamTypeCode: 'C',
        scamTypeLabelEn: '',
        scamTypeLabelTh: '',
        submittedAt: DateTime.now(),
        status: 'flagged',
        priorityFlag: false,
        evidenceCount: 0,
      );
      expect(item.isFlagged, true);
    });

    test('false when status is pending', () {
      final item = ModQueueItem(
        id: 'x',
        title: 'T',
        scamTypeCode: 'C',
        scamTypeLabelEn: '',
        scamTypeLabelTh: '',
        submittedAt: DateTime.now(),
        status: 'pending',
        priorityFlag: false,
        evidenceCount: 0,
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
      expect(detail.evidenceCount, 1);
      expect(detail.auditTrail, hasLength(1));
      expect(detail.auditTrail.first.action, 'submit');
      expect(detail.auditTrail.first.adminId, isNull);
    });

    test('isFlagged and isPending computed correctly on detail', () async {
      when(() => mockApi.fetchDetail(any())).thenAnswer(
          (_) async => {'report': {..._detailMap(), 'status': 'flagged'}});

      final detail = await repo.getDetail('r1');
      expect(detail.isFlagged, true);
      expect(detail.isPending, false);
    });

    test('detail mapper does not throw when server includes reporter fields',
        () async {
      when(() => mockApi.fetchDetail(any())).thenAnswer((_) async =>
          {'report': _detailMap(injectReporterFields: true)});

      final detail = await repo.getDetail('r1');
      // Sanity: the entity simply doesn't have anywhere to put the leaked
      // fields, and that's the point.
      expect(detail.id, 'r1');
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
      verify(() => mockApi.postAction('r1', 'reject', 'not enough evidence'))
          .called(1);
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
