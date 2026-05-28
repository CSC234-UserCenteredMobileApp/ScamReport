import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';
import 'package:mobile/features/moderation/presentation/mod_providers.dart';

ModQueueItem _item({
  required String id,
  String title = 'Fake bank OTP request',
  String scamTypeCode = 'phishing_sms',
  String scamTypeLabelEn = 'Phishing SMS',
  String scamTypeLabelTh = 'ฟิชชิง SMS',
  DateTime? submittedAt,
  String status = 'pending',
  bool priorityFlag = false,
  int evidenceCount = 1,
  String? aiConfidence,
}) {
  return ModQueueItem(
    id: id,
    title: title,
    scamTypeCode: scamTypeCode,
    scamTypeLabelEn: scamTypeLabelEn,
    scamTypeLabelTh: scamTypeLabelTh,
    submittedAt: submittedAt ?? DateTime.utc(2026, 4, 20, 8),
    status: status,
    priorityFlag: priorityFlag,
    evidenceCount: evidenceCount,
    aiConfidence: aiConfidence,
  );
}

ModQueueData _seed() => ModQueueData(
      items: [
        _item(
          id: 'r1',
          title: 'Fake bank OTP request',
          scamTypeCode: 'phishing_sms',
          scamTypeLabelEn: 'Phishing SMS',
          scamTypeLabelTh: 'ฟิชชิง SMS',
          aiConfidence: 'high',
          evidenceCount: 3,
          priorityFlag: true,
        ),
        _item(
          id: 'r2',
          title: 'Caller pretends MOI agent',
          scamTypeCode: 'phone_impersonation',
          scamTypeLabelEn: 'Phone Impersonation',
          scamTypeLabelTh: 'แอบอ้างทางโทรศัพท์',
          aiConfidence: 'medium',
          evidenceCount: 0,
        ),
        _item(
          id: 'r3',
          title: 'Investment plan',
          scamTypeCode: 'investment',
          scamTypeLabelEn: 'Investment Fraud',
          scamTypeLabelTh: 'การลงทุน',
          aiConfidence: null, // treated as 'unknown'
          evidenceCount: 2,
          status: 'flagged',
        ),
        _item(
          id: 'r4',
          title: 'Online shop never delivered',
          scamTypeCode: 'ecommerce_fraud',
          scamTypeLabelEn: 'E-commerce Fraud',
          scamTypeLabelTh: 'อีคอมเมิร์ซ',
          aiConfidence: 'low',
          evidenceCount: 1,
        ),
      ],
      pendingCount: 3,
      flaggedCount: 1,
    );

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      modQueueProvider.overrideWith((ref) async => _seed()),
    ],
  );
}

void main() {
  group('modFilteredQueueProvider — new filter dimensions', () {
    test('searchQuery matches title case-insensitively', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modSearchQueryProvider.notifier).state = 'OTP';
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id), ['r1']);
    });

    test('searchQuery matches scamTypeLabelEn substring', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modSearchQueryProvider.notifier).state = 'phone';
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id), ['r2']);
    });

    test('searchQuery matches scamTypeLabelTh substring', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modSearchQueryProvider.notifier).state = 'ฟิชชิง';
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id), ['r1']);
    });

    test('scam-type filter narrows to selected codes (OR)', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modScamTypeFilterProvider.notifier).state = const {
        'phishing_sms',
        'investment'
      };
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id).toSet(), {'r1', 'r3'});
    });

    test('AI confidence filter; null tier matches "unknown"', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modAiConfidenceFilterProvider.notifier).state = const {'unknown'};
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id), ['r3']);
    });

    test('priority-only excludes non-priority rows', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modPriorityOnlyProvider.notifier).state = true;
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id), ['r1']);
    });

    test('has-evidence-only excludes rows with zero evidence', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modHasEvidenceOnlyProvider.notifier).state = true;
      final items = c.read(modFilteredQueueProvider).requireValue;

      expect(items.map((i) => i.id).toSet(), {'r1', 'r3', 'r4'});
    });

    test('composition: scam type + AI confidence + evidence + sort', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      c.read(modScamTypeFilterProvider.notifier).state = const {
        'phishing_sms',
        'ecommerce_fraud'
      };
      c.read(modAiConfidenceFilterProvider.notifier).state = const {
        'high',
        'low'
      };
      c.read(modHasEvidenceOnlyProvider.notifier).state = true;
      c.read(modSortNewestFirstProvider.notifier).state = true;

      final items = c.read(modFilteredQueueProvider).requireValue;
      expect(items.map((i) => i.id), ['r1', 'r4']);
    });

    test('modAnyFilterActiveProvider reflects state correctly', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      expect(c.read(modAnyFilterActiveProvider), isFalse);

      c.read(modSearchQueryProvider.notifier).state = 'x';
      expect(c.read(modAnyFilterActiveProvider), isTrue);

      c.read(modSearchQueryProvider.notifier).state = '';
      c.read(modPriorityOnlyProvider.notifier).state = true;
      expect(c.read(modAnyFilterActiveProvider), isTrue);
    });

    test('empty filters preserve pre-existing behaviour', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(modQueueProvider.future);

      final items = c.read(modFilteredQueueProvider).requireValue;
      // Oldest first (default sort) — seed timestamps are identical so order
      // is insertion order: r1, r2, r3, r4.
      expect(items.map((i) => i.id), ['r1', 'r2', 'r3', 'r4']);
    });
  });
}
