// Generic binary download helper. Mirrors the auth + blob-save behaviour of
// download-pdf.ts but accepts any Content-Type and respects a server-stamped
// filename from `Content-Disposition` when present (falls back to the caller-
// supplied default otherwise). Used by the admin-exports feature for CSV /
// XLSX / ZIP downloads.

import { firebaseAuth } from '@/lib/auth/firebase';
import { ApiError } from './client';

const BASE = import.meta.env.VITE_API_BASE_URL ?? '';

function filenameFromHeader(disp: string | null, fallback: string): string {
  if (!disp) return fallback;
  const m = /filename="([^"]+)"/i.exec(disp);
  return m ? m[1]! : fallback;
}

export async function downloadBlob(path: string, fallbackFilename: string): Promise<void> {
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
  const filename = filenameFromHeader(res.headers.get('content-disposition'), fallbackFilename);
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
