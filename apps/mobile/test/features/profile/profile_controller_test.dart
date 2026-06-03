import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/di/auth.dart';
import 'package:mobile/features/profile/domain/user_profile.dart';
import 'package:mobile/features/profile/presentation/profile_providers.dart';

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockUser user;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    user = MockUser();
    when(() => user.uid).thenReturn('u1');
  });

  ProviderContainer containerWith({User? authUser}) {
    final c = ProviderContainer(
      overrides: [
        profileFirestoreProvider.overrideWithValue(firestore),
        authStateProvider.overrideWith((ref) => Stream.value(authUser)),
      ],
    );
    addTearDown(c.dispose);
    // @riverpod (autoDispose) providers need an active listener in container
    // tests, or they're torn down between reads.
    c.listen(profileControllerProvider, (_, __) {});
    return c;
  }

  test('emits null when signed out', () async {
    final c = containerWith(authUser: null);
    final profile = await c.read(profileControllerProvider.future);
    expect(profile, isNull);
  });

  test('emits null when signed in but no profile doc exists', () async {
    final c = containerWith(authUser: user);
    final profile = await c.read(profileControllerProvider.future);
    expect(profile, isNull);
  });

  test('save writes the profile and the stream emits it', () async {
    final c = containerWith(authUser: user);
    await c.read(profileControllerProvider.future); // wait for auth wiring

    await c.read(profileControllerProvider.notifier).save(
          displayName: 'Somchai',
        );

    // The watch stream picks up the write (poll until the notifier emits).
    UserProfile? updated;
    for (var i = 0; i < 50 && updated == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      updated = c.read(profileControllerProvider).valueOrNull;
    }
    expect(updated?.displayName, 'Somchai');

    // And the document physically landed at profiles/u1.
    final raw = await firestore.collection('profiles').doc('u1').get();
    expect(raw.data()!['displayName'], 'Somchai');
    expect(raw.data()!['updatedAt'], isNotNull);
  });

  test('save is a no-op when signed out', () async {
    final c = containerWith(authUser: null);
    await c.read(profileControllerProvider.future);

    await c.read(profileControllerProvider.notifier).save(displayName: 'X');

    final snapshot = await firestore.collection('profiles').get();
    expect(snapshot.docs, isEmpty);
  });
}
