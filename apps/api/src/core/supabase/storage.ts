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
