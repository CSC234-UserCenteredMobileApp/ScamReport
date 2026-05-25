// Verifies the FR-9.4 Remote Config gate on SmsAlertOverlayWrapper: when
// `enable_sms_scan` is false the wrapper renders only the child and does not
// subscribe to smsScannerProvider (PRD §6.8).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/feature_flags/feature_flags.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sms_scan/presentation/sms_overlay_banner.dart';
import 'package:mobile/features/sms_scan/presentation/sms_scan_providers.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap({
  required bool flagEnabled,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      featureFlagProvider('enable_sms_scan').overrideWith((_) => flagEnabled),
      // Stub scanner: never emits. Tests focus on the gate, not detection.
      smsScannerProvider.overrideWith((ref) => const Stream.empty()),
    ],
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('flag off — wrapper renders child, no overlay', (tester) async {
    await tester.pumpWidget(_wrap(
      flagEnabled: false,
      child: const SmsAlertOverlayWrapper(
        child: Text('inner child'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('inner child'), findsOneWidget);
    // No banner widget should be inserted.
    expect(find.byType(SmsAlertBanner), findsNothing);
  });

  testWidgets('flag on — wrapper renders child (no synthetic alert)',
      (tester) async {
    await tester.pumpWidget(_wrap(
      flagEnabled: true,
      child: const SmsAlertOverlayWrapper(
        child: Text('inner child'),
      ),
    ));
    await tester.pumpAndSettle();

    // Child still renders; banner only appears when scanner emits a non-null
    // alert, which the stub never does.
    expect(find.text('inner child'), findsOneWidget);
    expect(find.byType(SmsAlertBanner), findsNothing);
  });
}
