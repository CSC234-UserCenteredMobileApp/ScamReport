import { Buffer } from 'node:buffer';
import { getSupabase } from './client';

export async function uploadFile(
  bucket: string,
  path: string,
  body: Blob | ArrayBuffer | Uint8Array,
  options: { contentType?: string; upsert?: boolean } = {},
) {
  const { data, error } = await getSupabase()
    .storage.from(bucket)
    .upload(path, body, {
      contentType: options.contentType,
      upsert: options.upsert ?? false,
    });
  if (error) throw error;
  return data;
}

export async function getSignedUrl(
  bucket: string,
  path: string,
  expiresInSeconds = 3600,
): Promise<string> {
  const { data, error } = await getSupabase()
    .storage.from(bucket)
    .createSignedUrl(path, expiresInSeconds);
  if (error) throw error;
  return data.signedUrl;
}

export async function deleteFile(bucket: string, paths: string[]) {
  const { error } = await getSupabase().storage.from(bucket).remove(paths);
  if (error) throw error;
}

/**
 * Cross-bucket copy. Supabase's native `.copy()` works only within a single
 * bucket, so we download the source then re-upload to the destination. Used
 * by the Ask AI submit pipeline to promote chat-attachments → evidence
 * (iter-5 server-side draft sync).
 */
export async function copyFile(
  srcBucket: string,
  srcPath: string,
  dstBucket: string,
  dstPath: string,
  options: { contentType?: string } = {},
) {
  const supabase = getSupabase();
  const { data: blob, error: dlErr } = await supabase.storage
    .from(srcBucket)
    .download(srcPath);
  if (dlErr) throw dlErr;
  const buffer = Buffer.from(await blob.arrayBuffer());
  const { error: upErr } = await supabase.storage
    .from(dstBucket)
    .upload(dstPath, buffer, {
      contentType: options.contentType,
      upsert: false,
    });
  if (upErr) throw upErr;
}
