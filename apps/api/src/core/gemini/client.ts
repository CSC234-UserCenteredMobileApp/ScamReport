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
