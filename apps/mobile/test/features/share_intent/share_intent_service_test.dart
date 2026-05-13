import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/share_intent/data/share_intent_service.dart';

void main() {
  group('PluginShareIntentService — non-Android platform guard', () {
    // The test runner is desktop / web — never Android — so the service
    // must short-circuit and not call into the plugin (which would crash
    // because no MethodChannel is wired in tests).
    final service = PluginShareIntentService();

    test('initial() returns null', () async {
      final result = await service.initial();
      expect(result, isNull);
    });

    test('stream() yields no events and completes', () async {
      final events = await service.stream().toList();
      expect(events, isEmpty);
    });

    test('reset() is a no-op (does not throw)', () async {
      await service.reset();
    });
  });
}
