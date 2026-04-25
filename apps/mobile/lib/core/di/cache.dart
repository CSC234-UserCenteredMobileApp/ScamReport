import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache/app_database.dart';

// Drift / SQLite database — use for cached API responses, drafts, anything
// you'd query or watch reactively.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// SharedPreferences — small key/value store for user preferences, flags,
// last-selected filters. NOT for big or structured data.
//
// Loaded asynchronously; consume from a feature like:
//   final prefs = await ref.watch(sharedPreferencesProvider.future);
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

// FlutterSecureStorage — encrypted at rest. Use for refresh tokens or
// anything that mustn't appear in plain device storage.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});
