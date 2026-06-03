import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard (Clean Architecture rule from CLAUDE.md):
/// `lib/features/*/domain/` is pure Dart — no Flutter, no Firebase, no
/// Riverpod. Fails with the offending file + import line so violations are
/// caught at test time instead of code review.
void main() {
  test('domain layers contain no Flutter / Firebase / Riverpod imports', () {
    final banned = RegExp(
      r'''import\s+'package:(flutter[/_]|flutter/|firebase|cloud_firestore|flutter_riverpod)''',
    );

    final violations = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.contains('/domain/') || !path.endsWith('.dart')) continue;

      for (final line in entity.readAsLinesSync()) {
        if (banned.hasMatch(line)) {
          violations.add('$path -> $line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Domain must be pure Dart (CLAUDE.md). Violations:\n'
          '${violations.join('\n')}',
    );
  });
}
