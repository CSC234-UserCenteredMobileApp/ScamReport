import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openDatabaseConnection() => WebDatabase('app_db');
