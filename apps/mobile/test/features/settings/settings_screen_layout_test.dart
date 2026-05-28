import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_user.dart';
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

const _regularUser = AuthUser(
  id: 'u1',
  firebaseUid: 'firebase-uid-1',
  email: 'user@example.com',
  displayName: 'Test User',
  role: 'user',
  preferredLanguage: 'en',
);

const _adminUser = AuthUser(
  id: 'u2',
  firebaseUid: 'firebase-uid-2',
  email: 'admin@example.com',
  displayName: 'Admin User',
  role: 'admin',
  preferredLanguage: 'en',
);

Future<Widget> _buildSettings({AuthUser? user}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) async => user),
      settingsProvider.overrideWith(_FakeSettingsNotifier.new),
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
      // Stretch features default-off in prod; the layout tests don't care
      // either way but the gate must not blow up reading Remote Config.
      featureFlagProvider('enable_sms_scan').overrideWith((_) => false),
      featureFlagProvider('enable_call_screening').overrideWith((_) => false),
    ],
    child: _wrap(const SettingsScreen()),
  );
}

void main() {
  group('SettingsScreen — section layout', () {
    testWidgets('shows APPEARANCE section', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _buildSettings());
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
    });

    testWidgets('shows ALERTS & PROTECTION section', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _buildSettings());
      await tester.pumpAndSettle();

      expect(find.text('ALERTS & PROTECTION'), findsOneWidget);
    });

    testWidgets(
        'language and theme prefs are under APPEARANCE, not mixed with alerts',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _buildSettings());
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('ADMIN TOOLS section hidden for regular user', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _buildSettings(user: _regularUser));
      await tester.pumpAndSettle();

      expect(find.text('ADMIN TOOLS'), findsNothing);
      expect(find.text('Manage Announcements'), findsNothing);
    });

    testWidgets('ADMIN TOOLS section visible for admin user', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _buildSettings(user: _adminUser));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('ADMIN TOOLS'));
      expect(find.text('ADMIN TOOLS'), findsOneWidget);
      expect(find.text('Manage Announcements'), findsOneWidget);
    });
  });

  group('SettingsScreen — danger zone', () {
    testWidgets('Delete account and Danger zone are not present',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _buildSettings(user: _regularUser));
      await tester.pumpAndSettle();

      expect(find.text('Danger zone'), findsNothing);
      expect(find.text('Delete account'), findsNothing);
    });
  });
}
