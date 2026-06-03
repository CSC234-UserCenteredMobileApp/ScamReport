import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/profile_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProfileRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ProfileRepository(firestore);
  });

  test('fetch returns null when no profile exists', () async {
    expect(await repo.fetch('u1'), isNull);
  });

  test('save then fetch round-trips the profile', () async {
    await repo.save('u1', displayName: 'Somchai', preferredLanguage: 'th');

    final profile = await repo.fetch('u1');
    expect(profile, isNotNull);
    expect(profile!.displayName, 'Somchai');
    expect(profile.preferredLanguage, 'th');
    // serverTimestamp resolved by the backend (fake resolves immediately).
    expect(profile.updatedAt, isNotNull);
  });

  test('save merges — second save updates displayName only', () async {
    await repo.save('u1', displayName: 'A', preferredLanguage: 'en');
    await repo.save('u1', displayName: 'B', preferredLanguage: 'en');

    final profile = await repo.fetch('u1');
    expect(profile!.displayName, 'B');
  });

  test('watch emits the profile after a save', () async {
    // Subscribe first, then write — asserts the stream is live, not a replay.
    final firstNonNull = repo.watch('u1').firstWhere((p) => p != null);
    await repo.save('u1', displayName: 'Somchai', preferredLanguage: 'th');
    final first = await firstNonNull;
    expect(first!.displayName, 'Somchai');
  });

  test('writes land at profiles/{uid} with a server timestamp', () async {
    await repo.save('u9', displayName: 'X', preferredLanguage: 'en');
    final raw = await firestore.collection('profiles').doc('u9').get();
    expect(raw.exists, isTrue);
    expect(raw.data()!['updatedAt'], isNotNull);
  });
}
