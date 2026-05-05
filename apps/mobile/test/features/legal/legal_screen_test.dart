import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/legal/presentation/privacy_screen.dart';
import 'package:mobile/features/legal/presentation/terms_screen.dart';

void main() {
  testWidgets('PrivacyScreen renders without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  testWidgets('TermsScreen renders without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
    expect(find.byType(TermsScreen), findsOneWidget);
  });
}
