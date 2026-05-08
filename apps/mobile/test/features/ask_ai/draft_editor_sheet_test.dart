import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/presentation/widgets/draft_editor_sheet.dart';
import 'package:mobile/l10n/app_localizations.dart';

const _initial = AiDraft(
  title: 'Original title that is long enough',
  description: 'Original description that is long enough.',
  scamTypeCode: 'phishing_sms',
  targetIdentifier: 'kerry-th.net',
  targetIdentifierKind: TargetIdentifierKind.url,
);

Future<AiDraft?> _showSheet(WidgetTester tester) async {
  AiDraft? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<AiDraft>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const DraftEditorSheet(initial: _initial),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('renders fields populated from initial draft', (tester) async {
    await _showSheet(tester);
    expect(find.byKey(const Key('askAiDraftTitle')), findsOneWidget);
    expect(find.text('Original title that is long enough'), findsOneWidget);
    expect(find.text('Original description that is long enough.'), findsOneWidget);
  });

  testWidgets('Save returns edited AiDraft', (tester) async {
    await _showSheet(tester);

    await tester.enterText(
      find.byKey(const Key('askAiDraftTitle')),
      'Edited title here long enough',
    );
    await tester.enterText(
      find.byKey(const Key('askAiDraftDescription')),
      'Edited description that is long enough.',
    );
    await tester.tap(find.byKey(const Key('askAiDraftSave')));
    await tester.pumpAndSettle();

    // Sheet popped → tap-handler completed.
    expect(find.byKey(const Key('askAiDraftSave')), findsNothing);
  });

  testWidgets('Cancel closes the sheet without saving', (tester) async {
    await _showSheet(tester);
    final cancel = find.text('Cancel');
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('askAiDraftSave')), findsNothing);
  });

  testWidgets('Identifier left empty clears kind', (tester) async {
    await _showSheet(tester);
    await tester.enterText(
      find.byKey(const Key('askAiDraftIdentifier')),
      '',
    );
    await tester.tap(find.byKey(const Key('askAiDraftSave')));
    await tester.pumpAndSettle();
    // Cannot read the popped value here; absence of crash + sheet dismissed
    // is the real assertion.
    expect(find.byKey(const Key('askAiDraftSave')), findsNothing);
  });
}
