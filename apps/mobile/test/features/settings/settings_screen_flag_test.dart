// Gate behavior for the stretch features (FR-9.3 / FR-9.4). Verifies that
// the call-screening row and SMS smishing toggle in the settings screen are
// only rendered when the corresponding Remote Config flag is true (PRD §6.8).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
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

Future<Widget> _buildSettings({
  required bool smsScanEnabled,
  required bool callScreeningEnabled,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) async => null),
      settingsProvider.overrideWith(_FakeSettingsNotifier.new),
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
      featureFlagProvider('enable_sms_scan').overrideWith((_) => smsScanEnabled),
      featureFlagProvider('enable_call_screening')
          .overrideWith((_) => callScreeningEnabled),
    ],
    child: _wrap(const SettingsScreen()),
  );
}

void _setLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('SettingsScreen — stretch feature gates (Android)', () {
    testWidgets('both flags off — SMS toggle and call-screening tile hidden',
        (tester) async {
      _setLargeView(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(await _buildSettings(
          smsScanEnabled: false,
          callScreeningEnabled: false,
        ));
        await tester.pumpAndSettle();

        expect(find.text('SMS smishing detection'), findsNothing);
        expect(find.text('Call Screening'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('both flags on — both surfaces visible', (tester) async {
      _setLargeView(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(await _buildSettings(
          smsScanEnabled: true,
          callScreeningEnabled: true,
        ));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('SMS smishing detection'));
        expect(find.text('SMS smishing detection'), findsOneWidget);
        await tester.ensureVisible(find.text('Call Screening'));
        expect(find.text('Call Screening'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('only SMS flag on — call-screening still hidden',
        (tester) async {
      _setLargeView(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(await _buildSettings(
          smsScanEnabled: true,
          callScreeningEnabled: false,
        ));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('SMS smishing detection'));
        expect(find.text('SMS smishing detection'), findsOneWidget);
        expect(find.text('Call Screening'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
