import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ask_ai/domain/entities/ai_draft.dart';
import 'package:mobile/features/ask_ai/presentation/widgets/consent_card.dart';

const _draft = AiDraft(
  title: 'Fake Kerry parcel SMS',
  description: 'I received an SMS asking me to click a link…',
  scamTypeCode: 'phishing_sms',
);

Widget _wrap(ConsentCard card) => MaterialApp(home: Scaffold(body: card));

void main() {
  testWidgets('submit button is disabled until checkbox is ticked', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      _wrap(ConsentCard(
        draft: _draft,
        onEdit: () {},
        onAskRedraft: () {},
        onSubmit: () => submitted = true,
      )),
    );
    final submit = find.byKey(const Key('askAiConsentSubmit'));
    final FilledButton button = tester.widget(submit);
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const Key('askAiConsentCheckbox')));
    await tester.pumpAndSettle();

    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(submitted, isTrue);
  });

  testWidgets('shows submitting spinner when isSubmitting=true', (tester) async {
    await tester.pumpWidget(
      _wrap(ConsentCard(
        draft: _draft,
        isSubmitting: true,
        onEdit: () {},
        onAskRedraft: () {},
        onSubmit: () {},
      )),
    );
    expect(find.text('Submitting…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Edit / redraft callbacks fire', (tester) async {
    var edited = false;
    var redrafted = false;
    await tester.pumpWidget(
      _wrap(ConsentCard(
        draft: _draft,
        onEdit: () => edited = true,
        onAskRedraft: () => redrafted = true,
        onSubmit: () {},
      )),
    );
    await tester.tap(find.byKey(const Key('askAiConsentEdit')));
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    await tester.tap(find.byKey(const Key('askAiConsentRedraft')));
    await tester.pumpAndSettle();
    expect(redrafted, isTrue);
  });

  testWidgets('renders draft preview content', (tester) async {
    await tester.pumpWidget(
      _wrap(ConsentCard(
        draft: _draft,
        onEdit: () {},
        onAskRedraft: () {},
        onSubmit: () {},
      )),
    );
    expect(find.text('Fake Kerry parcel SMS'), findsOneWidget);
    expect(find.text('Type: phishing_sms'), findsOneWidget);
  });
}
