import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/di/auth.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/profile/presentation/edit_profile_sheet.dart';
import 'package:mobile/features/profile/presentation/profile_providers.dart';
import 'package:mobile/l10n/l10n.dart';

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockUser user;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    user = MockUser();
    when(() => user.uid).thenReturn('u1');
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: EditProfileSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('typing a name and saving writes profiles/{uid}', (tester) async {
    await pump(tester);

    await tester.enterText(
      find.byKey(const ValueKey('profile-display-name')),
      'Somchai',
    );
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('profiles').doc('u1').get();
    expect(doc.data()?['displayName'], 'Somchai');
  });

  testWidgets('empty name shows validation error and writes nothing',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter 1–50 characters'), findsOneWidget);
    final snapshot = await firestore.collection('profiles').get();
    expect(snapshot.docs, isEmpty);
  });
}
