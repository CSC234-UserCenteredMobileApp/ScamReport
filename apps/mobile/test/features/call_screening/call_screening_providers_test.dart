import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/call_screening/domain/blocked_call.dart';
import 'package:mobile/features/call_screening/domain/call_screening_repository.dart';
import 'package:mobile/features/call_screening/presentation/call_screening_providers.dart';

class _FakeRepo implements CallScreeningRepository {
  _FakeRepo({required this.enabled, this.shouldFailSync = false});
  bool enabled;
  bool shouldFailSync;
  bool syncCalled = false;

  @override
  Future<void> syncPhoneList() async {
    syncCalled = true;
    if (shouldFailSync) throw Exception('network error');
  }

  @override
  Future<List<BlockedCall>> getBlockedCalls() async => [];

  @override
  Future<void> setEnabled(bool v) async => enabled = v;

  @override
  Future<bool> isEnabled() async => enabled;
}

ProviderContainer _makeContainer(_FakeRepo repo) => ProviderContainer(
      overrides: [
        callScreeningRepositoryProvider.overrideWith((_) async => repo),
      ],
    );

void main() {
  group('callScreeningEnabledProvider', () {
    test('loads true when repo.isEnabled() returns true', () async {
      final repo = _FakeRepo(enabled: true);
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      final value = await c.read(callScreeningEnabledProvider.future);
      expect(value, isTrue);
    });

    test('loads false when repo.isEnabled() returns false', () async {
      final repo = _FakeRepo(enabled: false);
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      final value = await c.read(callScreeningEnabledProvider.future);
      expect(value, isFalse);
    });

    test('setEnabled(true) persists to repo', () async {
      final repo = _FakeRepo(enabled: false);
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      await c.read(callScreeningEnabledProvider.notifier).setEnabled(true);
      expect(repo.enabled, isTrue);
    });

    test('setEnabled(true) triggers syncPhoneList', () async {
      final repo = _FakeRepo(enabled: false);
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      await c.read(callScreeningEnabledProvider.notifier).setEnabled(true);
      expect(repo.syncCalled, isTrue);
    });

    test('setEnabled(false) does not trigger syncPhoneList', () async {
      final repo = _FakeRepo(enabled: true);
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      await c.read(callScreeningEnabledProvider.notifier).setEnabled(false);
      expect(repo.syncCalled, isFalse);
    });

    test('setEnabled(true) rethrows when sync fails', () async {
      final repo = _FakeRepo(enabled: false, shouldFailSync: true);
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      await expectLater(
        () => c.read(callScreeningEnabledProvider.notifier).setEnabled(true),
        throwsException,
      );
    });
  });
}
