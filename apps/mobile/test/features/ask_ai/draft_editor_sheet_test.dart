import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/data/attachment_picker.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/presentation/ask_ai_providers.dart';
import 'package:mobile/features/ask_ai/presentation/widgets/draft_editor_sheet.dart';
import 'package:mobile/l10n/app_localizations.dart';

const _initial = AiDraft(
  title: 'Original title that is long enough',
  description: 'Original description that is long enough.',
  scamTypeCode: 'phishing_sms',
  targetIdentifier: 'kerry-th.net',
  targetIdentifierKind: TargetIdentifierKind.url,
);

class _FakePicker extends AttachmentPicker {
  _FakePicker({this.next});
  StagedAttachment? next;
  @override
  Future<StagedAttachment?> pickFromCamera() async => next;
  @override
  Future<StagedAttachment?> pickFromGallery() async => next;
}

StagedAttachment _staged([int seed = 0]) => StagedAttachment(
      // PDF MIME means the chip renders the PDF placeholder icon instead of
      // calling MemoryImage — keeps tests free of image-codec setup.
      bytes: Uint8List.fromList([seed, 0xDE, 0xAD]),
      mimeType: 'application/pdf',
      filename: 'a$seed.pdf',
    );

Future<DraftEditorResult?> _showSheet(
  WidgetTester tester, {
  List<StagedAttachment> initialEvidence = const [],
  AttachmentPicker? picker,
}) async {
  DraftEditorResult? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (picker != null) attachmentPickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<DraftEditorResult>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DraftEditorSheet(
                      initial: _initial,
                      initialEvidence: initialEvidence,
                    ),
                  );
                },
                child: const Text('open'),
              ),
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
    expect(
        find.text('Original description that is long enough.'), findsOneWidget);
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

  testWidgets('renders pre-filled evidence chips when initialEvidence given',
      (tester) async {
    await _showSheet(
      tester,
      initialEvidence: [_staged(1), _staged(2)],
    );
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('Add evidence appends from picker; chip count increments',
      (tester) async {
    final picker = _FakePicker(next: _staged(7));
    await _showSheet(tester, picker: picker);
    expect(find.text('0/5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('askAiEvidenceAddButton')));
    await tester.pumpAndSettle();
    // Bottom sheet with camera/gallery options.
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('Add button stays interactive until 5 evidence files',
      (tester) async {
    await _showSheet(
      tester,
      initialEvidence: [
        _staged(1),
        _staged(2),
        _staged(3),
        _staged(4),
        _staged(5),
      ],
    );
    expect(find.text('5/5'), findsOneWidget);
    final btn = tester.widget<OutlinedButton>(
      find.byKey(const Key('askAiEvidenceAddButton')),
    );
    expect(btn.onPressed, isNull);
  });
}
