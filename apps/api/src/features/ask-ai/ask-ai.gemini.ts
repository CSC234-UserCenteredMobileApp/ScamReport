// Ask AI Gemini wiring — system prompt, structured-output schema, prompt
// builder, single entry point `runTurn`. Kept separate from service.ts so
// service.ts focuses on persistence + orchestration.

import { generateStructured, GeminiStructuredParseError } from '../../core/gemini/client';
import type { AskAiDraft } from '@my-product/shared';

// JSON Schema (subset Gemini accepts) describing the model's output. Mirrors
// the AskAiTurnResponse fields except userMessage / assistantMessage (those
// are server-side persistence concerns).
const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    reply: {
      type: 'string',
      description:
        'The assistant reply to show the user. Must be in the same language as the user. Never include a Scam/Safe/Suspicious/Unknown verdict label.',
    },
    intentDetected: {
      type: 'boolean',
      description: 'True iff the user describes a scam they personally experienced and may want to report.',
    },
    hasEnoughInfo: {
      type: 'boolean',
      description: 'True iff there is enough information in the conversation to draft a useful report (title, description, scam type at minimum).',
    },
    reportable: {
      type: 'boolean',
      description: 'True iff the situation looks like a scam worth reporting. Internal-only signal — never surfaced as a verdict label.',
    },
    draft: {
      type: 'object',
      nullable: true,
      properties: {
        title: { type: 'string' },
        description: { type: 'string' },
        scamTypeCode: {
          type: 'string',
          enum: [
            'phone_impersonation',
            'phishing_sms',
            'fake_qr',
            'ecommerce_fraud',
            'other',
            'investment_fraud',
            'romance_scam',
          ],
        },
        targetIdentifier: { type: 'string', nullable: true },
        targetIdentifierKind: {
          type: 'string',
          nullable: true,
          enum: ['phone', 'url', 'other', null],
        },
      },
      required: ['title', 'description', 'scamTypeCode'],
    },
    similarReportIds: {
      type: 'array',
      items: { type: 'string' },
      description: 'Echo back at most 5 of the provided similar-report IDs that genuinely match.',
    },
  },
  required: [
    'reply',
    'intentDetected',
    'hasEnoughInfo',
    'reportable',
    'similarReportIds',
  ],
} as const;

const SYSTEM_PROMPT = `You are ScamReport's "Ask AI" assistant. You help users in Thailand understand whether something they describe is a scam, and you help them file a report when appropriate. Your reply MUST follow these rules:

1. Reply in the same language the user wrote in (Thai or English). Default to Thai if uncertain.
2. NEVER label the situation as "Scam", "Safe", "Suspicious", or "Unknown". Those are reserved for the formal POST /check verdict screen, not Ask AI. Describe risk in plain words instead.
3. If the user is asking a general question, answer it conversationally. Use the provided "Verified scam reports near this topic" list when you can. Reference the matched report IDs.
4. If the user describes something that personally happened to them (clicked a link, transferred money, gave OTP, was contacted by a fraudster), set intentDetected=true. If you have enough information (a brief description, a likely scam type), also set hasEnoughInfo=true and reportable=true and produce a draft.
5. Draft fields:
   - title: short headline of the incident (4-120 chars).
   - description: 2-4 sentences in the user's language, neutral and factual.
   - scamTypeCode: one of the enum values listed in the schema. Pick the closest match; use "other" only when nothing fits.
   - targetIdentifier: the phone / URL / handle the user mentioned, or null. Strip surrounding punctuation.
   - targetIdentifierKind: 'phone', 'url', 'other', or null.
6. If the user is just asking a general question (no personal incident), set intentDetected=false. Still set reportable=true ONLY if you believe the described item itself looks scammy and the user might want to report it on someone's behalf — otherwise reportable=false.
7. similarReportIds: echo at most 5 of the provided "Verified scam reports near this topic" IDs that genuinely match the user's situation. If the topic is unrelated, return [].
8. NEVER fabricate a report ID. Only echo the IDs you were given.
9. Keep replies under 200 words.`;

export type SimilarReportSummary = {
  id: string;
  title: string;
  scamTypeCode: string;
  scamTypeLabel: string;
  verifiedAt: string | null;
};

export type GeminiTurnInput = {
  history: Array<{ role: 'user' | 'assistant'; content: string }>;
  similarReports: SimilarReportSummary[];
  latestUserMessage: string;
};

export type GeminiTurnOutput = {
  reply: string;
  intentDetected: boolean;
  hasEnoughInfo: boolean;
  reportable: boolean;
  draft: AskAiDraft | null;
  similarReportIds: string[];
};

function buildPrompt(input: GeminiTurnInput): string {
  const lines: string[] = [];
  lines.push(SYSTEM_PROMPT);
  lines.push('');
  if (input.similarReports.length > 0) {
    lines.push('Verified scam reports near this topic (use as context, do not invent IDs):');
    for (const r of input.similarReports) {
      lines.push(
        `- id=${r.id} type=${r.scamTypeCode} (${r.scamTypeLabel}) — ${r.title}`,
      );
    }
    lines.push('');
  }
  if (input.history.length > 0) {
    lines.push('Conversation so far (oldest first):');
    for (const m of input.history) {
      lines.push(`${m.role === 'user' ? 'USER' : 'ASSISTANT'}: ${m.content}`);
    }
    lines.push('');
  }
  lines.push(`USER: ${input.latestUserMessage}`);
  lines.push('');
  lines.push('Respond now as a JSON object matching the response schema.');
  return lines.join('\n');
}

const FALLBACK_OUTPUT: GeminiTurnOutput = {
  reply:
    "I'm having trouble generating a response right now. Please try rephrasing your question, or try again in a moment.",
  intentDetected: false,
  hasEnoughInfo: false,
  reportable: false,
  draft: null,
  similarReportIds: [],
};

/**
 * Single Gemini turn call. Returns a typed output and never throws —
 * structured-output failures and Gemini transport failures both collapse to
 * `FALLBACK_OUTPUT` with a clear assistant reply. Errors are logged so the
 * structured-parse failure rate is observable in production.
 */
export async function runTurn(input: GeminiTurnInput): Promise<GeminiTurnOutput> {
  const prompt = buildPrompt(input);
  try {
    const result = await generateStructured<GeminiTurnOutput>(prompt, RESPONSE_SCHEMA);
    return normaliseOutput(result, input);
  } catch (err) {
    if (err instanceof GeminiStructuredParseError) {
      console.error('[ask-ai] structured-parse-failure', { raw: err.raw });
    } else {
      console.error('[ask-ai] gemini-transport-failure', { err });
    }
    return FALLBACK_OUTPUT;
  }
}

// Defensive cleanup: clamp similarReportIds to those Gemini was actually
// shown, drop fabricated IDs, ensure draft fields are well-formed when
// reportable=true is set.
function normaliseOutput(
  raw: GeminiTurnOutput,
  input: GeminiTurnInput,
): GeminiTurnOutput {
  const allowedIds = new Set(input.similarReports.map((r) => r.id));
  const similarReportIds = (raw.similarReportIds ?? [])
    .filter((id) => typeof id === 'string' && allowedIds.has(id))
    .slice(0, 5);

  let draft = raw.draft ?? null;
  // If the model claims reportable but produced no draft, drop reportable
  // so the UI never renders "Submit report?" without a draft to submit.
  if (raw.reportable && !draft) {
    return {
      ...raw,
      reportable: false,
      similarReportIds,
    };
  }
  // Ensure optional fields have explicit nulls (TypeBox response schema is
  // stricter than the Gemini schema — undefined would fail at the route
  // layer).
  if (draft) {
    draft = {
      title: draft.title,
      description: draft.description,
      scamTypeCode: draft.scamTypeCode,
      targetIdentifier: draft.targetIdentifier ?? null,
      targetIdentifierKind: (draft.targetIdentifierKind ?? null) as
        | 'phone'
        | 'url'
        | 'other'
        | null,
    };
  }
  return {
    reply: raw.reply ?? FALLBACK_OUTPUT.reply,
    intentDetected: Boolean(raw.intentDetected),
    hasEnoughInfo: Boolean(raw.hasEnoughInfo),
    reportable: Boolean(raw.reportable),
    draft,
    similarReportIds,
  };
}

export const __TEST__ = {
  buildPrompt,
  RESPONSE_SCHEMA,
  FALLBACK_OUTPUT,
};
