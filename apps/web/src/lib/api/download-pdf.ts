// Download a binary PDF from an admin endpoint and save it via a temporary
// blob URL. Auth is attached the same way apiFetch does it (fresh Firebase
// ID token). Replaces window.print() so the saved document matches the
// mobile export exactly.

import { firebaseAuth } from '@/lib/auth/firebase';
import { ApiError } from './client';

const BASE = import.meta.env.VITE_API_BASE_URL ?? '';

export async function downloadPdf(path: string, filename: string): Promise<void> {
  const user = firebaseAuth.currentUser;
  const token = user ? await user.getIdToken() : null;

  const res = await fetch(`${BASE}${path}`, {
    method: 'GET',
    headers: token ? { Authorization: `Bearer ${token}` } : undefined,
  });

  if (res.status === 401) {
    await firebaseAuth.signOut().catch(() => undefined);
    throw new ApiError(401, 'UNAUTHORIZED');
  }
  if (res.status === 403) {
    throw new ApiError(403, 'FORBIDDEN');
  }
  if (!res.ok) {
    throw new ApiError(res.status, `HTTP_${res.status}`);
  }

  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  try {
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.append(a);
    a.click();
    a.remove();
  } finally {
    URL.revokeObjectURL(url);
  }
}
