import 'package:drift/drift.dart';

import '../../../core/cache/app_database.dart';
import 'ask_ai_state_codec.dart';

/// Single-row drift wrapper that holds the Ask AI session snapshot.
/// Reuses the existing `Drafts` table (`type='ask_ai_state'`) to avoid a
/// drift schema migration. The row is unique-by-type at the app level —
/// `save` is upsert, `load` is read, `clear` is delete.
class AskAiPersistence {
  AskAiPersistence(this._db);
  final AppDatabase _db;

  static const String _draftType = 'ask_ai_state';

  Future<AskAiPersistedState?> load() async {
    final row = await (_db.select(_db.drafts)
          ..where((t) => t.type.equals(_draftType))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final decoded = AskAiStateCodec.decode(row.payload);
    if (decoded == null) {
      // Row is corrupt or version-mismatched — drop it so subsequent loads
      // start fresh.
      await clear();
      return null;
    }
    return decoded;
  }

  Future<void> save(AskAiPersistedState state) async {
    if (state.isEmpty) {
      await clear();
      return;
    }
    final payload = AskAiStateCodec.encode(state);
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.delete(_db.drafts)..where((t) => t.type.equals(_draftType)))
          .go();
      await _db.into(_db.drafts).insert(
            DraftsCompanion.insert(
              type: _draftType,
              payload: payload,
              updatedAt: now,
            ),
          );
    });
  }

  Future<void> clear() async {
    await (_db.delete(_db.drafts)..where((t) => t.type.equals(_draftType)))
        .go();
  }
}
