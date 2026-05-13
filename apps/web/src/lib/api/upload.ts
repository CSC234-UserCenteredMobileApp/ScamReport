import type { TSchema, Static } from '@sinclair/typebox';
import type { TypeCheck } from '@sinclair/typebox/compiler';
import { firebaseAuth } from '@/lib/auth/firebase';
import { ApiError } from './client';

const BASE = import.meta.env.VITE_API_BASE_URL ?? '';

interface UploadOptions {
  onProgress?: (loaded: number, total: number) => void;
  signal?: AbortSignal;
}

// XHR-based multipart upload so the caller can render real progress.
// `fetch` does not surface upload progress (no ReadableStream support for
// request bodies in browsers as of 2026), so we drop down to XMLHttpRequest
// here. The response body is parsed + checked by the same precompiled
// TypeBox validator that `apiFetch` uses — schema discipline is preserved.
export async function uploadWithProgress<S extends TSchema>(
  path: string,
  formData: FormData,
  validator: TypeCheck<S>,
  options: UploadOptions = {},
): Promise<Static<S>> {
  const user = firebaseAuth.currentUser;
  const token = user ? await user.getIdToken() : null;

  return new Promise<Static<S>>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', `${BASE}${path}`);
    if (token) {
      xhr.setRequestHeader('Authorization', `Bearer ${token}`);
    }
    // Do NOT set Content-Type — XHR sets multipart boundary itself.

    if (options.onProgress) {
      xhr.upload.addEventListener('progress', (evt) => {
        if (evt.lengthComputable) {
          options.onProgress!(evt.loaded, evt.total);
        }
      });
    }

    if (options.signal) {
      const onAbort = () => xhr.abort();
      options.signal.addEventListener('abort', onAbort, { once: true });
    }

    xhr.addEventListener('abort', () => {
      reject(new ApiError(0, 'ABORTED'));
    });
    xhr.addEventListener('error', () => {
      reject(new ApiError(0, 'NETWORK_ERROR'));
    });
    xhr.addEventListener('load', () => {
      const status = xhr.status;
      if (status === 401) {
        void firebaseAuth.signOut().catch(() => undefined);
        return reject(new ApiError(401, 'UNAUTHORIZED'));
      }
      if (status === 403) {
        return reject(new ApiError(403, 'FORBIDDEN'));
      }
      let parsed: unknown = undefined;
      try {
        parsed = JSON.parse(xhr.responseText);
      } catch {
        parsed = undefined;
      }
      if (status < 200 || status >= 300) {
        return reject(new ApiError(status, `HTTP_${status}`, parsed));
      }
      if (!validator.Check(parsed)) {
        const errors = [...validator.Errors(parsed)].slice(0, 5);
        return reject(new ApiError(0, 'SCHEMA_MISMATCH', errors));
      }
      resolve(parsed as Static<S>);
    });

    xhr.send(formData);
  });
}
