import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sms_scan/domain/sms_alert.dart';
import 'package:mobile/features/sms_scan/presentation/sms_overlay_banner.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Stack(children: [child])),
    ),
  );
}

SmsAlert _scamAlert() => SmsAlert(
      id: 1,
      senderMasked: 'XXXX-5678',
      bodyExcerpt: 'Click here to claim your prize',
      verdict: 'scam',
      detectedAt: DateTime(2026, 5, 3, 12),
      isRead: false,
    );

void main() {
  testWidgets('SmsAlertBanner shows sender and excerpt', (tester) async {
    await tester.pumpWidget(_wrap(
      SmsAlertBanner(
        alert: _scamAlert(),
        onDismiss: () {},
        onView: () {},
      ),
    ));

    expect(find.text('XXXX-5678'), findsOneWidget);
    expect(find.text('Click here to claim your prize'), findsOneWidget);
  });

  testWidgets('SmsAlertBanner calls onDismiss when × tapped', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(_wrap(
      SmsAlertBanner(
        alert: _scamAlert(),
        onDismiss: () => dismissed = true,
        onView: () {},
      ),
    ));

    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  testWidgets('SmsAlertBanner calls onView when View tapped', (tester) async {
    var viewed = false;
    await tester.pumpWidget(_wrap(
      SmsAlertBanner(
        alert: _scamAlert(),
        onDismiss: () {},
        onView: () => viewed = true,
      ),
    ));

    await tester.tap(find.text('View'));
    expect(viewed, isTrue);
  });
}
