import { describe, expect, mock, test } from 'bun:test';

// iter-5 language locking: verify locale flows through buildPrompt and
// fallbackOutput emits Thai when locale='th'.

let lastPrompt = '';
mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
  generateStructured: async (prompt: string) => {
    lastPrompt = prompt;
    throw new Error('forced gemini failure for fallback test');
  },
  GeminiStructuredParseError: class extends Error {
    constructor(msg: string, public raw: string) {
      super(msg);
    }
  },
  generateMultimodal: async () => ({ text: '', parsed: null }),
  inlinePart: () => ({ inlineData: { data: '', mimeType: '' } }),
}));

const { runTurn, __TEST__ } = await import('../src/features/ask-ai/ask-ai.gemini');

describe('Ask AI locale plumbing (iter-5)', () => {
  test('buildPrompt prefixes RESPOND IN: Thai for locale=th', () => {
    const built = __TEST__.buildPrompt({
      history: [],
      similarReports: [],
      latestUserMessage: 'sawasdee',
      locale: 'th',
    });
    expect(built).toContain('RESPOND IN: Thai');
    expect(built.indexOf('RESPOND IN')).toBeLessThan(
      built.indexOf('You are ScamReport'),
    );
  });

  test('buildPrompt prefixes RESPOND IN: English for locale=en', () => {
    const built = __TEST__.buildPrompt({
      history: [],
      similarReports: [],
      latestUserMessage: 'hello',
      locale: 'en',
    });
    expect(built).toContain('RESPOND IN: English');
  });

  test('buildPrompt omits RESPOND IN line when locale missing', () => {
    const built = __TEST__.buildPrompt({
      history: [],
      similarReports: [],
      latestUserMessage: 'hi',
    });
    expect(built).not.toContain('RESPOND IN:');
  });

  test('runTurn fallback emits Thai message when locale=th', async () => {
    const out = await runTurn({
      history: [],
      similarReports: [],
      latestUserMessage: 'help',
      locale: 'th',
    });
    expect(out.reply).toContain('ขออภัย');
    expect(out.intentDetected).toBe(false);
    expect(out.reportable).toBe(false);
  });

  test('runTurn fallback emits English message when locale=en', async () => {
    const out = await runTurn({
      history: [],
      similarReports: [],
      latestUserMessage: 'help',
      locale: 'en',
    });
    expect(out.reply).toContain("I'm having trouble");
  });
});

// Reference lastPrompt to avoid an unused-binding lint when the test file is
// extended later.
export const __for_lint = () => lastPrompt;
