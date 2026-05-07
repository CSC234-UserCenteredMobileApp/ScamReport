import { GoogleGenAI, type Part } from '@google/genai';

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

// Test seam — overrides the lazy singleton with a stub. Used by route tests
// that mock Gemini without setting a real API key.
export function __setGeminiClientForTest(client: unknown): void {
  _client = client as GoogleGenAI;
}

export const DEFAULT_MODEL = 'gemini-2.5-flash';
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

// =============================================================================
// Structured + multimodal helpers (used by Ask AI — see features/ask-ai/)
// =============================================================================
//
// Both helpers thin-wrap models.generateContent. They differ only in:
//   - generateStructured: passes a JSON Schema as responseSchema and
//     parses+returns typed JSON. Throws if Gemini returns malformed JSON.
//   - generateMultimodal: accepts inline image/PDF parts alongside text.
//
// Failure model:
//   - On HTTP / network failure, the underlying SDK throws — caller catches
//     and emits a localised fallback (FR-4.x — see ask-ai.service).
//   - On JSON.parse failure inside generateStructured, we throw
//     `GeminiStructuredParseError` so callers can distinguish parse failures
//     from transport failures (logged + Crashlytics tagged on the API side).

export class GeminiStructuredParseError extends Error {
  constructor(
    message: string,
    public readonly raw: string,
  ) {
    super(message);
    this.name = 'GeminiStructuredParseError';
  }
}

export interface GenerateStructuredOptions {
  model?: string;
  // Multi-part contents (text + inline images/PDFs). When omitted, `prompt`
  // is sent as a single text part.
  parts?: Part[];
  // Temperature override; structured output is best with a low value.
  temperature?: number;
}

export async function generateStructured<T>(
  prompt: string,
  responseSchema: object,
  opts: GenerateStructuredOptions = {},
): Promise<T> {
  const contents: Part[] = opts.parts ?? [{ text: prompt }];
  const response = await getClient().models.generateContent({
    model: opts.model ?? DEFAULT_MODEL,
    contents,
    config: {
      responseMimeType: 'application/json',
      // SDK accepts JSON Schema objects via SchemaUnion. The TypeBox schema
      // is JSON-schema-shaped already, so it's passed straight through.
      responseSchema: responseSchema as never,
      temperature: opts.temperature ?? 0.2,
    },
  });

  const raw = response.text ?? '';
  if (!raw) {
    throw new GeminiStructuredParseError('Gemini returned empty response', raw);
  }
  try {
    return JSON.parse(raw) as T;
  } catch (err) {
    throw new GeminiStructuredParseError(
      `Gemini structured output is not valid JSON: ${(err as Error).message}`,
      raw,
    );
  }
}

export interface GenerateMultimodalOptions {
  model?: string;
  // When passed, we request structured JSON output and parse it into T.
  responseSchema?: object;
  temperature?: number;
}

export async function generateMultimodal<T = string>(
  parts: Part[],
  opts: GenerateMultimodalOptions = {},
): Promise<{ text: string; parsed: T | null }> {
  const config: Record<string, unknown> = {
    temperature: opts.temperature ?? 0.2,
  };
  if (opts.responseSchema) {
    config.responseMimeType = 'application/json';
    config.responseSchema = opts.responseSchema;
  }

  const response = await getClient().models.generateContent({
    model: opts.model ?? DEFAULT_MODEL,
    contents: parts,
    config: config as never,
  });

  const text = response.text ?? '';
  let parsed: T | null = null;
  if (opts.responseSchema && text) {
    try {
      parsed = JSON.parse(text) as T;
    } catch (err) {
      throw new GeminiStructuredParseError(
        `Gemini multimodal output is not valid JSON: ${(err as Error).message}`,
        text,
      );
    }
  }
  return { text, parsed };
}

// Helper: build an inline-data Part from a binary buffer (e.g., a Supabase
// download). Used by ask-ai.service when the user attached files.
export function inlinePart(data: Uint8Array | ArrayBuffer, mimeType: string): Part {
  const bytes = data instanceof Uint8Array ? data : new Uint8Array(data);
  return {
    inlineData: {
      data: bytesToBase64(bytes),
      mimeType,
    },
  };
}

function bytesToBase64(bytes: Uint8Array): string {
  // Bun + Node: Buffer is available globally.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return (globalThis as any).Buffer.from(bytes).toString('base64');
}
