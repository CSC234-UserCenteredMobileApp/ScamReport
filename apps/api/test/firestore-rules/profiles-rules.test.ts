// Firestore security-rules tests — run against the Firestore emulator:
//
//   bun run test:rules        (wraps `firebase emulators:exec`)
//
// Auto-skips when no emulator is reachable so the plain `bun test` suite
// stays green in environments without Java/the emulator.
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

const OWNER = 'user-aaa';
const STRANGER = 'user-bbb';

const validProfile = () => ({
  displayName: 'Somchai',
  preferredLanguage: 'th',
  updatedAt: serverTimestamp(),
});

describe.skipIf(!emulatorHost)('firestore.rules — profiles/{uid}', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initializeTestEnvironment({
      projectId: 'scamreport-rules-test',
      firestore: {
        rules: readFileSync(
          resolve(import.meta.dir, '../../../../firestore.rules'),
          'utf8',
        ),
      },
    });
  });

  afterAll(async () => {
    await env?.cleanup();
  });

  const ownerDb = () => env.authenticatedContext(OWNER).firestore();
  const strangerDb = () => env.authenticatedContext(STRANGER).firestore();
  const anonDb = () => env.unauthenticatedContext().firestore();
  const ownerRef = (db = ownerDb()) => doc(db, 'profiles', OWNER);

  test('owner creates a valid profile with serverTimestamp', async () => {
    await env.clearFirestore();
    await assertSucceeds(setDoc(ownerRef(), validProfile()));
  });

  test('a stranger cannot create someone else’s profile', async () => {
    await env.clearFirestore();
    await assertFails(
      setDoc(doc(strangerDb(), 'profiles', OWNER), validProfile()),
    );
  });

  test('owner reads own profile; stranger and anon cannot', async () => {
    await env.clearFirestore();
    await assertSucceeds(setDoc(ownerRef(), validProfile()));
    await assertSucceeds(getDoc(ownerRef()));
    await assertFails(getDoc(doc(strangerDb(), 'profiles', OWNER)));
    await assertFails(getDoc(doc(anonDb(), 'profiles', OWNER)));
  });

  test('update touching only whitelisted keys succeeds', async () => {
    await env.clearFirestore();
    await assertSucceeds(setDoc(ownerRef(), validProfile()));
    await assertSucceeds(
      updateDoc(ownerRef(), {
        displayName: 'Somchai J.',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('update smuggling an extra key is rejected (diff().affectedKeys())', async () => {
    await env.clearFirestore();
    await assertSucceeds(setDoc(ownerRef(), validProfile()));
    await assertFails(
      updateDoc(ownerRef(), {
        displayName: 'Somchai J.',
        role: 'admin', // not in the whitelist
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('client-supplied clock value is rejected (request.time check)', async () => {
    await env.clearFirestore();
    await assertFails(
      setDoc(ownerRef(), {
        ...validProfile(),
        updatedAt: new Date('2020-01-01T00:00:00Z'),
      }),
    );
  });

  test('oversize displayName is rejected (field-level validation)', async () => {
    await env.clearFirestore();
    await assertFails(
      setDoc(ownerRef(), {
        ...validProfile(),
        displayName: 'x'.repeat(51),
      }),
    );
  });

  test('unknown preferredLanguage is rejected', async () => {
    await env.clearFirestore();
    await assertFails(
      setDoc(ownerRef(), { ...validProfile(), preferredLanguage: 'xx' }),
    );
  });

  test('owner can delete own profile', async () => {
    await env.clearFirestore();
    await assertSucceeds(setDoc(ownerRef(), validProfile()));
    await assertSucceeds(deleteDoc(ownerRef()));
  });
});

describe.skipIf(!emulatorHost)('firestore.rules — existing mirrors stay locked', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initializeTestEnvironment({
      projectId: 'scamreport-rules-test-mirrors',
      firestore: {
        rules: readFileSync(
          resolve(import.meta.dir, '../../../../firestore.rules'),
          'utf8',
        ),
      },
    });
  });

  afterAll(async () => {
    await env?.cleanup();
  });

  test('alerts are public-read, never client-writable', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'alerts', 'a1')));
    await assertFails(setDoc(doc(db, 'alerts', 'a1'), { title: 'spoof' }));
  });

  test('my-reports are owner-read only and never client-writable', async () => {
    const owner = env.authenticatedContext(OWNER).firestore();
    const stranger = env.authenticatedContext(STRANGER).firestore();
    await assertSucceeds(
      getDoc(doc(owner, 'my-reports', OWNER, 'items', 'r1')),
    );
    await assertFails(
      getDoc(doc(stranger, 'my-reports', OWNER, 'items', 'r1')),
    );
    await assertFails(
      setDoc(doc(owner, 'my-reports', OWNER, 'items', 'r1'), { status: 'x' }),
    );
  });

  test('default deny still covers arbitrary collections', async () => {
    const db = env.authenticatedContext(OWNER).firestore();
    await assertFails(setDoc(doc(collection(db, 'random')), { a: 1 }));
    await assertFails(getDoc(doc(db, 'users', OWNER)));
  });
});
