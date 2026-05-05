import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/call_screening/domain/blocked_call.dart';
import 'package:mobile/features/call_screening/domain/call_screening_repository.dart';
import 'package:mobile/features/call_screening/presentation/call_screening_providers.dart';
import 'package:mobile/features/call_screening/presentation/call_screening_screen.dart';
import 'package:mobile/l10n/l10n.dart';

class _FakeRepo implements CallScreeningRepository {
  _FakeRepo({
    this.enabled = false,
    this.shouldFailSync = false,
    this.blockedCalls = const [],
  });
  bool enabled;
  bool shouldFailSync;
  List<BlockedCall> blockedCalls;

  @override
  Future<void> syncPhoneList() async {
    if (shouldFailSync) throw Exception('network error');
  }

  @override
  Future<List<BlockedCall>> getBlockedCalls() async => blockedCalls;

  @override
  Future<void> setEnabled(bool v) async => enabled = v;

  @override
  Future<bool> isEnabled() async => enabled;
}

Widget _themed(Widget widget) {
  return MaterialApp(
    theme: lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widget,
  );
}

void main() {
  group('CallScreeningScreen', () {
    testWidgets('shows screen title and enable toggle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callScreeningSdkVersionProvider.overrideWith((ref) async => 29),
            callScreeningIsDefaultProvider.overrideWith((ref) async => false),
            callScreeningRepositoryProvider.overrideWith(
              (_) async => _FakeRepo(),
            ),
          ],
          child: _themed(const CallScreeningScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Call Screening'), findsAtLeast(1));
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows setup card when not set as default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callScreeningSdkVersionProvider.overrideWith((ref) async => 29),
            callScreeningIsDefaultProvider.overrideWith((ref) async => false),
            callScreeningRepositoryProvider.overrideWith(
              (_) async => _FakeRepo(enabled: true),
            ),
          ],
          child: _themed(const CallScreeningScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Setup required'), findsOneWidget);
    });

    testWidgets('shows unsupported message on Android < 10', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callScreeningSdkVersionProvider.overrideWith((ref) async => 28),
            callScreeningIsDefaultProvider.overrideWith((ref) async => false),
            callScreeningRepositoryProvider.overrideWith(
              (_) async => _FakeRepo(),
            ),
          ],
          child: _themed(const CallScreeningScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Android 10'), findsOneWidget);
    });

    testWidgets('shows blocked calls log when enabled and set as default',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final calls = [
        BlockedCall(
          number: '+66812345678',
          blockedAt: DateTime.utc(2026, 5, 1, 10),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callScreeningSdkVersionProvider.overrideWith((ref) async => 29),
            callScreeningIsDefaultProvider.overrideWith((ref) async => true),
            callScreeningRepositoryProvider.overrideWith(
              (_) async => _FakeRepo(enabled: true, blockedCalls: calls),
            ),
          ],
          child: _themed(const CallScreeningScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('+66812345678'), findsOneWidget);
      expect(find.text('1 call screened'), findsOneWidget);
    });

    testWidgets('toggle enable persists to repository', (tester) async {
      final repo = _FakeRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callScreeningSdkVersionProvider.overrideWith((ref) async => 29),
            callScreeningIsDefaultProvider.overrideWith((ref) async => true),
            callScreeningRepositoryProvider.overrideWith((_) async => repo),
          ],
          child: _themed(const CallScreeningScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(repo.enabled, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(repo.enabled, isTrue);
    });

    testWidgets('shows snackbar when sync fails on enable', (tester) async {
      final repo = _FakeRepo(shouldFailSync: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callScreeningSdkVersionProvider.overrideWith((ref) async => 29),
            callScreeningIsDefaultProvider.overrideWith((ref) async => true),
            callScreeningRepositoryProvider.overrideWith((_) async => repo),
          ],
          child: _themed(const CallScreeningScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not update phone list — cached data will be used'),
        findsOneWidget,
      );
    });
  });
}
