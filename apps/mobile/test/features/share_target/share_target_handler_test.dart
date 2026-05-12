import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/share_target/presentation/share_target_handler.dart';

void main() {
  group('ShareTargetHandler.truncateForNotification', () {
    test('short text returned unchanged', () {
      expect(ShareTargetHandler.truncateForNotification('hello', 60), 'hello');
    });

    test('text exactly at max returned unchanged', () {
      final s = 'a' * 60;
      expect(ShareTargetHandler.truncateForNotification(s, 60), s);
    });

    test('text over max is cut and appended with ellipsis', () {
      final s = 'a' * 61;
      final result = ShareTargetHandler.truncateForNotification(s, 60);
      expect(result, '${'a' * 60}…');
      expect(result.length, 61); // 60 chars + ellipsis char
    });

    test('empty string returned as-is', () {
      expect(ShareTargetHandler.truncateForNotification('', 60), '');
    });
  });

  group('ShareTargetHandler.verdictNotificationLabel', () {
    test('scam → warning emoji + Scam', () {
      final (title, emoji) = ShareTargetHandler.verdictNotificationLabel('scam');
      expect(title, 'Scam');
      expect(emoji, '⚠️');
    });

    test('suspicious → warning emoji + Suspicious', () {
      final (title, emoji) =
          ShareTargetHandler.verdictNotificationLabel('suspicious');
      expect(title, 'Suspicious');
      expect(emoji, '⚠️');
    });

    test('safe → checkmark + Safe', () {
      final (title, emoji) = ShareTargetHandler.verdictNotificationLabel('safe');
      expect(title, 'Safe');
      expect(emoji, '✓');
    });

    test('unknown → question mark + Unknown', () {
      final (title, emoji) =
          ShareTargetHandler.verdictNotificationLabel('unknown');
      expect(title, 'Unknown');
      expect(emoji, '?');
    });

    test('unrecognised verdict → question mark + Unknown', () {
      final (title, emoji) =
          ShareTargetHandler.verdictNotificationLabel('other');
      expect(title, 'Unknown');
      expect(emoji, '?');
    });
  });
}
