import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/app_database.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_persistence.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_state_codec.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';

// iter-5: drafts + evidence sync server-side. Drift only persists composer
// state (conversationId + stagedAttachments + conversationAttachments).

StagedAttachment _staged([int seed = 0]) => StagedAttachment(
      bytes: Uint8List.fromList([seed, 0xDE, 0xAD]),
      mimeType: 'image/jpeg',
      filename: 'a$seed.jpg',
    );

void main() {
  group('AskAiStateCodec (v=2)', () {
    test('round-trips composer state', () {
      final original = AskAiPersistedState(
        conversationId: 'conv-1',
        userId: 'firebase-uid-A',
        stagedAttachments: [_staged(3)],
        conversationAttachments: [_staged(4)],
      );
      final encoded = AskAiStateCodec.encode(original);
      final decoded = AskAiStateCodec.decode(encoded)!;
      expect(decoded.conversationId, 'conv-1');
      expect(decoded.userId, 'firebase-uid-A');
      expect(decoded.stagedAttachments, hasLength(1));
      expect(decoded.stagedAttachments.first.bytes, _staged(3).bytes);
      expect(decoded.conversationAttachments, hasLength(1));
    });

    test('rejects v=1 payloads (iter-4 codec)', () {
      const legacy =
          '{"v": 1, "conversationId": "x", "activeDraft": null, "stagedAttachments": []}';
      expect(AskAiStateCodec.decode(legacy), isNull);
    });

    test('rejects malformed JSON', () {
      expect(AskAiStateCodec.decode('not json'), isNull);
    });

    test('isEmpty returns true when nothing populated', () {
      expect(AskAiPersistedState().isEmpty, isTrue);
      expect(AskAiPersistedState(conversationId: 'c').isEmpty, isFalse);
      expect(
        AskAiPersistedState(stagedAttachments: [_staged()]).isEmpty,
        isFalse,
      );
    });
  });

  group('AskAiPersistence (uid-scoped)', () {
    late AppDatabase db;
    late AskAiPersistence persistence;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      persistence = AskAiPersistence(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('load returns null on first call', () async {
      expect(await persistence.load(), isNull);
    });

    test('save then load round-trips', () async {
      final original = AskAiPersistedState(
        conversationId: 'conv-1',
        userId: 'uid-A',
        stagedAttachments: [_staged(1)],
      );
      await persistence.save(original);
      final loaded = await persistence.load('uid-A');
      expect(loaded, isNotNull);
      expect(loaded!.conversationId, 'conv-1');
      expect(loaded.stagedAttachments, hasLength(1));
    });

    test('load with foreign uid wipes the row', () async {
      await persistence.save(AskAiPersistedState(
        conversationId: 'a',
        userId: 'uid-A',
      ));
      expect(await persistence.load('uid-B'), isNull);
      // Row was cleared.
      expect(await persistence.load('uid-A'), isNull);
    });

    test('save with empty state deletes the row', () async {
      await persistence.save(AskAiPersistedState(conversationId: 'c'));
      expect(await persistence.load(), isNotNull);
      await persistence.save(AskAiPersistedState());
      expect(await persistence.load(), isNull);
    });

    test('clearForUser purges the row', () async {
      await persistence.save(AskAiPersistedState(
        conversationId: 'c',
        userId: 'uid-A',
      ));
      await persistence.clearForUser('uid-A');
      expect(await persistence.load(), isNull);
    });

    test('save twice keeps a single row (upsert)', () async {
      await persistence.save(AskAiPersistedState(conversationId: 'a'));
      await persistence.save(AskAiPersistedState(conversationId: 'b'));
      final loaded = await persistence.load();
      expect(loaded!.conversationId, 'b');
      final all = await db.select(db.drafts).get();
      expect(all.where((r) => r.type == 'ask_ai_state').length, 1);
    });

    test('corrupt payload is dropped on load', () async {
      final now = DateTime.now();
      await db.into(db.drafts).insert(
            DraftsCompanion.insert(
              type: 'ask_ai_state',
              payload: 'not-valid-json',
              updatedAt: now,
            ),
          );
      expect(await persistence.load(), isNull);
      final all = await db.select(db.drafts).get();
      expect(all.where((r) => r.type == 'ask_ai_state'), isEmpty);
    });
  });
}
