import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// Generic key/value cache for arbitrary JSON payloads (typically API responses).
// `value` holds JSON-encoded data; `expiresAt` is null for non-expiring entries.
class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// User-generated drafts (half-typed reports etc.). `type` lets multiple
// features share the table; `payload` is JSON-encoded feature-specific data.
class Drafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();
}

// SMS smishing alerts detected by the on-device classifier.
// `senderMasked` and `bodyExcerpt` are truncated/masked for privacy.
class SmsAlerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderMasked => text()();
  TextColumn get bodyExcerpt => text()();
  TextColumn get verdict => text()();
  DateTimeColumn get detectedAt => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [CacheEntries, Drafts, SmsAlerts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(smsAlerts);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
