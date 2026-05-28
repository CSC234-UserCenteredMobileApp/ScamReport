import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/search/domain/scam_type_item.dart';
import 'package:mobile/features/search/presentation/filter_bottom_sheet.dart';
import 'package:mobile/features/search/presentation/search_providers.dart';
import 'package:mobile/l10n/l10n.dart';

const _scamTypes = [
  ScamTypeItem(
      code: 'phone',
      labelEn: 'Phone Scam',
      labelTh: 'หลอกลวง',
      displayOrder: 1),
  ScamTypeItem(
      code: 'phishing',
      labelEn: 'Phishing',
      labelTh: 'ฟิชชิ่ง',
      displayOrder: 2),
];

Widget _wrap({
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showFilterSheet(ctx),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FilterBottomSheet', () {
    testWidgets('shows sort section with both options', (tester) async {
      await tester.pumpWidget(_wrap(overrides: [
        scamTypesProvider.overrideWith((_) async => _scamTypes),
      ]));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('SORT BY'), findsOneWidget);
      expect(find.text('Latest verified'), findsOneWidget);
      expect(find.text('Most reported'), findsOneWidget);
    });

    testWidgets('shows scam type section with checkboxes', (tester) async {
      await tester.pumpWidget(_wrap(overrides: [
        scamTypesProvider.overrideWith((_) async => _scamTypes),
      ]));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('SCAM TYPE'), findsOneWidget);
      expect(find.text('Phone Scam'), findsOneWidget);
      expect(find.text('Phishing'), findsOneWidget);
    });

    testWidgets('apply button closes the sheet', (tester) async {
      await tester.pumpWidget(_wrap(overrides: [
        scamTypesProvider.overrideWith((_) async => _scamTypes),
      ]));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('SORT BY'), findsNothing);
    });

    testWidgets('reset button resets sort to latest', (tester) async {
      final container = ProviderContainer(overrides: [
        scamTypesProvider.overrideWith((_) async => _scamTypes),
        searchSortByProvider.overrideWith((ref) => 'reportCount'),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showFilterSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(container.read(searchSortByProvider), 'latest');
    });

    testWidgets('reset button clears scam type selections', (tester) async {
      final container = ProviderContainer(overrides: [
        scamTypesProvider.overrideWith((_) async => _scamTypes),
        searchScamTypeFilterProvider.overrideWith((ref) => ['phone']),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showFilterSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(container.read(searchScamTypeFilterProvider), isEmpty);
    });

    testWidgets('tapping scam type checkbox toggles selection', (tester) async {
      final container = ProviderContainer(overrides: [
        scamTypesProvider.overrideWith((_) async => _scamTypes),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showFilterSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap "Phone Scam" checkbox
      await tester.tap(find.text('Phone Scam'));
      await tester.pumpAndSettle();

      expect(container.read(searchScamTypeFilterProvider), contains('phone'));

      // Tap again to deselect
      await tester.tap(find.text('Phone Scam'));
      await tester.pumpAndSettle();

      expect(container.read(searchScamTypeFilterProvider),
          isNot(contains('phone')));
    });

    testWidgets('shows Thai labels when locale is Thai', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          scamTypesProvider.overrideWith((_) async => _scamTypes),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showFilterSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('หลอกลวง'), findsOneWidget);
      expect(find.text('ฟิชชิ่ง'), findsOneWidget);
    });
  });
}
