import { GoogleGenAI } from '@google/genai';

let _client: GoogleGenAI | null = null;

function getClient(): GoogleGenAI {
  if (_client) return _client;
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not set.');
  }
  _client = new GoogleGenAI({ apiKey });
  return _client;
}

export const DEFAULT_MODEL = 'gemini-2.0-flash';
// text-embedding-004 discontinued Nov 2025; gemini-embedding-001 is the replacement.
// outputDimensionality: 768 keeps the vector(768) DB column intact.
export const EMBEDDING_MODEL = 'gemini-embedding-001';

export async function generateText(
  prompt: string,
  model: string = DEFAULT_MODEL,
): Promise<string> {
  const response = await getClient().models.generateContent({
    model,
    contents: prompt,
  });
  return response.text ?? '';
}

export async function embed(text: string): Promise<number[]> {
  const response = await getClient().models.embedContent({
    model: EMBEDDING_MODEL,
    contents: text,
    config: { outputDimensionality: 768 },
  });
  return response.embeddings?.[0]?.values ?? [];
}
