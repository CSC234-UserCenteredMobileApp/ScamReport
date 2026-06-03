import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/app_lock/presentation/widgets/pin_pad.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _app(Widget child) => MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('backspace + biometric keys expose semantic labels (a11y)',
      (tester) async {
    await tester.pumpWidget(_app(PinPad(
      onDigit: (_) {},
      onBackspace: () {},
      showBiometric: true,
      onBiometric: () {},
    )));
    await tester.pumpAndSettle();

    // English defaults from the test harness locale.
    expect(find.bySemanticsLabel('Delete'), findsOneWidget);
    expect(find.bySemanticsLabel('Use biometric'), findsOneWidget);
  });

  testWidgets('backspace removes the last digit and no-ops when empty',
      (tester) async {
    final pressed = <String>[];
    var backspaces = 0;
    await tester.pumpWidget(_app(PinPad(
      onDigit: pressed.add,
      onBackspace: () => backspaces++,
    )));

    await tester.tap(find.byKey(const ValueKey('pinpad-7')));
    await tester.tap(find.byKey(const ValueKey('pinpad-back')));
    await tester.pump();

    expect(pressed, ['7']);
    expect(backspaces, 1);
  });
}
