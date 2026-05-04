import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/check/presentation/check_input_screen.dart';
import 'package:mobile/l10n/l10n.dart';

Widget _wrap(Widget widget, {List<Override> overrides = const []}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => widget),
      GoRoute(
        path: '/verdict',
        builder: (_, __) => const Scaffold(body: Text('verdict')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('CheckInputScreen', () {
    testWidgets('"Run check" button disabled when field is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckInputScreen()));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Run check'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('"Run check" button enabled after typing text', (tester) async {
      await tester.pumpWidget(_wrap(const CheckInputScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '+66 84 419 2270');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Run check'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('"Try a number" chip pre-fills the text field', (tester) async {
      await tester.pumpWidget(_wrap(const CheckInputScreen()));
      await tester.pump();

      await tester.tap(find.widgetWithText(ActionChip, 'Try a number'));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, contains('+66'));
    });

    testWidgets('"Try a link" chip pre-fills with a URL', (tester) async {
      await tester.pumpWidget(_wrap(const CheckInputScreen()));
      await tester.pump();

      await tester.tap(find.widgetWithText(ActionChip, 'Try a link'));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, contains('http'));
    });

    testWidgets('initialText pre-populates the field', (tester) async {
      await tester.pumpWidget(
        _wrap(const CheckInputScreen(initialText: 'prefilled text')),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'prefilled text');
    });
  });
}
