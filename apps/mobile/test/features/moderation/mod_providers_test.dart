import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/moderation/domain/mod_report.dart';
import 'package:mobile/features/moderation/presentation/mod_providers.dart';

ModQueueItem _item(String id, DateTime submittedAt, {bool flagged = false}) =>
    ModQueueItem(
      id: id,
      title: 'Report $id',
      scamTypeCode: 'PHISH',
      scamTypeLabelEn: 'Phishing',
      scamTypeLabelTh: 'ฟิชชิง',
      submittedAt: submittedAt,
      status: flagged ? 'flagged' : 'pending',
      priorityFlag: flagged,
      evidenceCount: 1,
      reporterHandle: '@user',
    );

final _t1 = DateTime.utc(2026, 4, 20, 8);
final _t2 = DateTime.utc(2026, 4, 20, 10);
final _t3 = DateTime.utc(2026, 4, 20, 12);

ModQueueData _fakeQueue() => ModQueueData(
      items: [
        _item('r1', _t1),
        _item('r2', _t2, flagged: true),
        _item('r3', _t3),
      ],
      pendingCount: 2,
      flaggedCount: 1,
    );

ProviderContainer _container({ModQueueData? queue}) {
  return ProviderContainer(
    overrides: [
      modQueueProvider.overrideWith(
        (ref) async => queue ?? _fakeQueue(),
      ),
    ],
  );
}

void main() {
  group('modFilteredQueueProvider', () {
    test('default: all items sorted oldest-first', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(modQueueProvider.future);
      final result = container.read(modFilteredQueueProvider);

      final items = result.requireValue;
      expect(items, hasLength(3));
      expect(items[0].id, 'r1');
      expect(items[1].id, 'r2');
      expect(items[2].id, 'r3');
    });

    test('sort newest-first reverses order', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(modQueueProvider.future);
      container.read(modSortNewestFirstProvider.notifier).state = true;

      final result = container.read(modFilteredQueueProvider);
      final items = result.requireValue;

      expect(items[0].id, 'r3');
      expect(items[1].id, 'r2');
      expect(items[2].id, 'r1');
    });

    test('flagged filter returns only flagged items', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(modQueueProvider.future);
      container.read(modFilterFlaggedProvider.notifier).state = true;

      final result = container.read(modFilteredQueueProvider);
      final items = result.requireValue;

      expect(items, hasLength(1));
      expect(items.first.id, 'r2');
    });

    test('filter + newest-first combined', () async {
      final queue = ModQueueData(
        items: [
          _item('r1', _t1, flagged: true),
          _item('r2', _t2),
          _item('r3', _t3, flagged: true),
        ],
        pendingCount: 1,
        flaggedCount: 2,
      );
      final container = _container(queue: queue);
      addTearDown(container.dispose);

      await container.read(modQueueProvider.future);
      container.read(modFilterFlaggedProvider.notifier).state = true;
      container.read(modSortNewestFirstProvider.notifier).state = true;

      final items = container.read(modFilteredQueueProvider).requireValue;
      expect(items, hasLength(2));
      expect(items[0].id, 'r3'); // newer first
      expect(items[1].id, 'r1');
    });

    test('propagates loading state from modQueueProvider', () {
      final container = ProviderContainer(
        overrides: [
          modQueueProvider.overrideWith(
            (ref) => Completer<ModQueueData>().future,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(modFilteredQueueProvider);
      expect(result, isA<AsyncLoading>());
    });
  });
}
