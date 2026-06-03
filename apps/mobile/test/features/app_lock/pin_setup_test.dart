import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/presentation/pin_setup_sheet.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _app(Widget child) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Future<void> _enter(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(ValueKey('pinpad-$d')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('matching entry + confirmation reports the PIN', (tester) async {
    String? result;
    await tester.pumpWidget(
      _app(PinSetupView(onComplete: (pin) => result = pin)),
    );

    await _enter(tester, '123456'); // enter step
    await _enter(tester, '123456'); // confirm step

    expect(result, '123456');
  });

  testWidgets('mismatch shows an error and does not report a PIN',
      (tester) async {
    String? result;
    await tester.pumpWidget(
      _app(PinSetupView(onComplete: (pin) => result = pin)),
    );

    await _enter(tester, '123456');
    await _enter(tester, '654321');

    expect(result, isNull);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PinSetupView)),
    )!;
    expect(find.text(l10n.appLockPinMismatch), findsOneWidget);
  });
}
