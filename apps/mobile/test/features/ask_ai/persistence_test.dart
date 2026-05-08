import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/app_database.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_persistence.dart';
import 'package:mobile/features/ask_ai/data/ask_ai_state_codec.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';

const _draft = AiDraft(
  title: 'Fake Kerry parcel SMS',
  description: 'I received an SMS asking me to click a link.',
  scamTypeCode: 'phishing_sms',
  targetIdentifier: 'kerry-th.net',
  targetIdentifierKind: TargetIdentifierKind.url,
);

StagedAttachment _staged([int seed = 0]) => StagedAttachment(
      bytes: Uint8List.fromList([seed, 0xDE, 0xAD]),
      mimeType: 'image/jpeg',
      filename: 'a$seed.jpg',
    );

void main() {
  group('AskAiStateCodec', () {
    test('round-trips draft + evidence + attachments', () {
      final original = AskAiPersistedState(
        conversationId: 'conv-1',
        activeDraft: _draft,
        activeEvidence: [_staged(1), _staged(2)],
        stagedAttachments: [_staged(3)],
        conversationAttachments: [_staged(4)],
      );
      final encoded = AskAiStateCodec.encode(original);
      final decoded = AskAiStateCodec.decode(encoded)!;
      expect(decoded.conversationId, 'conv-1');
      expect(decoded.activeDraft?.title, _draft.title);
      expect(decoded.activeEvidence, hasLength(2));
      expect(decoded.activeEvidence!.first.bytes, _staged(1).bytes);
      expect(decoded.stagedAttachments, hasLength(1));
      expect(decoded.conversationAttachments, hasLength(1));
    });

    test('rejects version mismatch', () {
      const corrupt = '{"v": 999, "conversationId": "x"}';
      expect(AskAiStateCodec.decode(corrupt), isNull);
    });

    test('rejects malformed JSON', () {
      expect(AskAiStateCodec.decode('not json'), isNull);
    });

    test('isEmpty returns true when nothing populated', () {
      expect(AskAiPersistedState().isEmpty, isTrue);
      expect(AskAiPersistedState(conversationId: 'c').isEmpty, isFalse);
      expect(
          AskAiPersistedState(activeEvidence: [_staged()]).isEmpty, isFalse);
    });
  });

  group('AskAiPersistence', () {
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
        activeDraft: _draft,
        stagedAttachments: [_staged(1)],
      );
      await persistence.save(original);
      final loaded = await persistence.load();
      expect(loaded, isNotNull);
      expect(loaded!.conversationId, 'conv-1');
      expect(loaded.stagedAttachments, hasLength(1));
    });

    test('save with empty state deletes the row', () async {
      await persistence.save(AskAiPersistedState(conversationId: 'c'));
      expect(await persistence.load(), isNotNull);
      await persistence.save(AskAiPersistedState());
      expect(await persistence.load(), isNull);
    });

    test('clear deletes the row', () async {
      await persistence.save(AskAiPersistedState(conversationId: 'c'));
      await persistence.clear();
      expect(await persistence.load(), isNull);
    });

    test('save twice keeps a single row (upsert)', () async {
      await persistence.save(AskAiPersistedState(conversationId: 'a'));
      await persistence.save(AskAiPersistedState(conversationId: 'b'));
      final loaded = await persistence.load();
      expect(loaded!.conversationId, 'b');
      // Verify only one row exists.
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
      // load() also clears the corrupt row.
      final all = await db.select(db.drafts).get();
      expect(all.where((r) => r.type == 'ask_ai_state'), isEmpty);
    });
  });
}
