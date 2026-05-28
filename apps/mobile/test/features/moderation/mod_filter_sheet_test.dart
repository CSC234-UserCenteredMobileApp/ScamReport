import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/moderation/presentation/mod_filter_sheet.dart';
import 'package:mobile/features/moderation/presentation/mod_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SafeArea(child: ModFilterSheet())),
    ),
  );
}

void main() {
  setUp(() {
    // The sheet's ListView is lazy — off-screen children are not in the
    // element tree. A taller viewport keeps the entire filter surface
    // (sort + scam types + AI confidence + flags) measured + built.
  });

  Future<void> pumpSheet(
      WidgetTester tester, ProviderContainer container) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
  }

  testWidgets('ticking a scam-type checkbox updates the provider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpSheet(tester, container);

    expect(container.read(modScamTypeFilterProvider), isEmpty);

    // The "Phishing SMS" checkbox is rendered as a CheckboxListTile in en locale.
    await tester.tap(find.text('Phishing SMS'));
    await tester.pump();

    expect(container.read(modScamTypeFilterProvider), contains('phishing_sms'));
  });

  testWidgets('tapping an AI confidence chip toggles it in the set',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpSheet(tester, container);

    await tester.tap(find.text('High'));
    await tester.pump();
    expect(container.read(modAiConfidenceFilterProvider), contains('high'));

    // Tap again — should remove.
    await tester.tap(find.text('High'));
    await tester.pump();
    expect(container.read(modAiConfidenceFilterProvider).contains('high'),
        isFalse);
  });

  testWidgets('priority + has-evidence switches flip booleans', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpSheet(tester, container);

    final priorityFinder = find.text('Priority-flagged only');
    expect(priorityFinder, findsOneWidget);
    await tester.tap(priorityFinder);
    await tester.pump();
    expect(container.read(modPriorityOnlyProvider), isTrue);

    final evidenceFinder = find.text('Has evidence');
    await tester.tap(evidenceFinder);
    await tester.pump();
    expect(container.read(modHasEvidenceOnlyProvider), isTrue);
  });

  testWidgets('Reset clears all five filter providers', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Pre-seed all five filters.
    container.read(modSearchQueryProvider.notifier).state = 'bank';
    container.read(modScamTypeFilterProvider.notifier).state = const {
      'phishing_sms'
    };
    container.read(modAiConfidenceFilterProvider.notifier).state = const {
      'high'
    };
    container.read(modPriorityOnlyProvider.notifier).state = true;
    container.read(modHasEvidenceOnlyProvider.notifier).state = true;

    await pumpSheet(tester, container);

    await tester.tap(find.text('Reset'));
    await tester.pump();

    expect(container.read(modSearchQueryProvider), '');
    expect(container.read(modScamTypeFilterProvider), isEmpty);
    expect(container.read(modAiConfidenceFilterProvider), isEmpty);
    expect(container.read(modPriorityOnlyProvider), isFalse);
    expect(container.read(modHasEvidenceOnlyProvider), isFalse);
  });
}
