import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around Crashlytics so call sites don't have to null-check
/// Firebase init. When Firebase isn't initialised (missing config files in
/// dev) every call no-ops + logs through `dart:developer` instead.
class CrashReporter {
  const CrashReporter();

  bool get _available => Firebase.apps.isNotEmpty;

  Future<void> setUserId(String? uid) async {
    if (!_available) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
  }

  Future<void> setKey(String key, Object value) async {
    if (!_available) return;
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  Future<void> log(String message) async {
    if (!_available) return;
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Record a caught exception as non-fatal. Safe to call from any layer.
  /// In debug or when Firebase isn't initialised, logs to `developer.log`
  /// so the stack trace still surfaces locally.
  Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
  }) async {
    if (kDebugMode || !_available) {
      developer.log(
        reason ?? 'non-fatal',
        name: 'crash_reporter',
        error: error,
        stackTrace: stack,
      );
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      information: information,
      fatal: false,
    );
  }
}

final crashReporterProvider = Provider<CrashReporter>((ref) {
  return const CrashReporter();
});
