import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/auth_providers.dart';
import 'package:mobile/features/settings/data/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_state.dart';
import 'package:mobile/features/settings/presentation/settings_providers.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget widget) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    );

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<SettingsState> build() async => SettingsState.defaults;

  @override
  Future<void> save(SettingsState next) async {
    state = AsyncValue.data(next);
  }
}

Future<Widget> _buildSettings({bool consentGiven = false}) async {
  SharedPreferences.setMockInitialValues(
    consentGiven ? {'sms_scan_consent_given': true} : {},
  );
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) async => null),
      settingsProvider.overrideWith(_FakeSettingsNotifier.new),
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
    ],
    child: _wrap(const SettingsScreen()),
  );
}

void main() {
  group('SettingsScreen — SMS smishing toggle', () {
    testWidgets('hidden on non-Android platform', (tester) async {
      // Flutter tests default to Android; explicitly set iOS to verify hiding.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(await _buildSettings());
        await tester.pumpAndSettle();

        expect(find.text('SMS smishing detection'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('visible on Android platform', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(await _buildSettings());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('SMS smishing detection'));
        expect(find.text('SMS smishing detection'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('consent dialog shown on first enable', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(await _buildSettings(consentGiven: false));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('SMS smishing detection'));
        await tester.tap(find.text('SMS smishing detection'));
        await tester.pumpAndSettle();

        expect(find.text('Enable SMS scanning?'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('consent dialog skipped when already consented', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(await _buildSettings(consentGiven: true));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('SMS smishing detection'));
        await tester.tap(find.text('SMS smishing detection'));
        await tester.pumpAndSettle();

        // No consent dialog — permission request fires instead.
        expect(find.text('Enable SMS scanning?'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
