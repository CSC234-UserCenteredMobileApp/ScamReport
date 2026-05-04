import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/cache/app_database.dart';
import '../domain/check_repository.dart';
import '../domain/check_result.dart';
import 'check_api_client.dart';

class CheckRepositoryImpl implements CheckRepository {
  CheckRepositoryImpl(this._api, this._db);

  final CheckApiClient _api;
  final AppDatabase _db;

  static const _maxCachedEntries = 100;

  String _cacheKey(CheckQuery query) =>
      'check:${query.type}:${query.payload.toLowerCase().trim()}';

  @override
  Future<CheckResult> runCheck(CheckQuery query) async {
    final key = _cacheKey(query);

    // Try cache first
    final cached = await (_db.select(_db.cacheEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();

    if (cached != null) {
      final json = jsonDecode(cached.value) as Map<String, dynamic>;
      return _fromJson(json, fromCache: true);
    }

    // Fetch from API
    final result = await _api.check(query);

    // Persist to cache
    final now = DateTime.now();
    await _db.into(_db.cacheEntries).insertOnConflictUpdate(
          CacheEntriesCompanion(
            key: Value(key),
            value: Value(jsonEncode(_toJson(result))),
            updatedAt: Value(now),
          ),
        );

    // Evict oldest entries if over limit
    await _evictOldest();

    return result;
  }

  Future<void> _evictOldest() async {
    final count = await _db.cacheEntries
        .count(
          where: (t) => t.key.like('check:%'),
        )
        .getSingle();

    if (count > _maxCachedEntries) {
      final oldest = await (_db.select(_db.cacheEntries)
            ..where((t) => t.key.like('check:%'))
            ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)])
            ..limit(count - _maxCachedEntries))
          .get();

      for (final entry in oldest) {
        await (_db.delete(_db.cacheEntries)
              ..where((t) => t.key.equals(entry.key)))
            .go();
      }
    }
  }

  Map<String, dynamic> _toJson(CheckResult r) => {
        'verdict': r.verdict,
        'matchedCount': r.matchedCount,
        'matches': r.matches
            .map((m) => {
                  'id': m.id,
                  'title': m.title,
                  'scamType': m.scamType,
                  'verifiedAt': m.verifiedAt,
                })
            .toList(),
      };

  CheckResult _fromJson(Map<String, dynamic> json, {required bool fromCache}) {
    final rawMatches = json['matches'] as List<dynamic>;
    return CheckResult(
      verdict: json['verdict'] as String,
      matchedCount: json['matchedCount'] as int,
      matches: rawMatches.map((m) {
        final item = m as Map<String, dynamic>;
        return ReportSummaryItem(
          id: item['id'] as String,
          title: item['title'] as String,
          scamType: item['scamType'] as String,
          verifiedAt: item['verifiedAt'] as String,
        );
      }).toList(),
      fromCache: fromCache,
    );
  }
}
