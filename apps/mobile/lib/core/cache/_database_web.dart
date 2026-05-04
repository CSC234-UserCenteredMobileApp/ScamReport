// ignore_for_file: deprecated_member_use
// drift/web.dart (WebDatabase) is deprecated in favour of drift/wasm.dart.
// WASM migration requires compiled worker + sqlite3.wasm build artifacts —
// tracked as tech debt. Suppressed here so --fatal-infos CI passes.
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openDatabaseConnection() => WebDatabase('app_db');
