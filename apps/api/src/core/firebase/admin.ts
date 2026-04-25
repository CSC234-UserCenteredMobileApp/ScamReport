import { readFileSync } from 'node:fs';
import { initializeApp, cert, getApps, type App } from 'firebase-admin/app';

let _app: App | null = null;

export function getFirebaseAdmin(): App {
  if (_app) return _app;
  const existing = getApps()[0];
  if (existing) {
    _app = existing;
    return _app;
  }

  const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!path) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT_PATH is not set — required to use firebase-admin.',
    );
  }

  const serviceAccount = JSON.parse(readFileSync(path, 'utf-8'));
  _app = initializeApp({ credential: cert(serviceAccount) });
  return _app;
}
