import 'package:drift/drift.dart';

import '../../../core/cache/app_database.dart';
import 'ask_ai_state_codec.dart';

/// Single-row drift wrapper that holds the Ask AI session snapshot.
/// Reuses the existing `Drafts` table (`type='ask_ai_state'`) to avoid a
/// drift schema migration. The row is unique-by-type at the app level —
/// `save` is upsert, `load` is read, `clear` is delete.
///
/// iter-5: rows are scoped by Firebase UID via the JSON payload so signing
/// out user X + signing in user Y on the same device doesn't leak X's
/// composer state into Y's session. `load()` returns null when the persisted
/// uid does not match.
class AskAiPersistence {
  AskAiPersistence(this._db);
  final AppDatabase _db;

  static const String _draftType = 'ask_ai_state';

  /// Loads the persisted snapshot for `userId`. When the snapshot belongs
  /// to a different uid (sign-out → different account), it is cleared and
  /// `null` returned.
  Future<AskAiPersistedState?> load([String? userId]) async {
    final row = await (_db.select(_db.drafts)
          ..where((t) => t.type.equals(_draftType))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final decoded = AskAiStateCodec.decode(row.payload);
    if (decoded == null) {
      await clear();
      return null;
    }
    if (userId != null && decoded.userId != null && decoded.userId != userId) {
      // Foreign uid — wipe and start fresh.
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

  /// Idempotent purge — used on sign-out to ensure the next account doesn't
  /// see this device's composer state. Currently aliases `clear()` because
  /// the table holds a single ask_ai_state row; named explicitly so the
  /// auth listener call site is self-documenting.
  Future<void> clearForUser(String userId) => clear();
}
