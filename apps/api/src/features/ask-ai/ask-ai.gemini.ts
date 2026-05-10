// Ask AI Gemini wiring — system prompt, structured-output schema, prompt
// builder, single entry point `runTurn`. Kept separate from service.ts so
// service.ts focuses on persistence + orchestration.

import {
  generateMultimodal,
  generateStructured,
  GeminiStructuredParseError,
  inlinePart,
} from '../../core/gemini/client';
import type { AskAiDraft, AskAiLocale } from '@my-product/shared';

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
    missingFacts: {
      type: 'array',
      items: {
        type: 'string',
        enum: ['description', 'targetIdentifier', 'scamTypeCue', 'userAction'],
      },
      description:
        'Facts NOT yet gathered from the user. Empty list ONLY when hasEnoughInfo=true. When non-empty, the reply must end with one specific question targeting missingFacts[0].',
    },
  },
  required: [
    'reply',
    'intentDetected',
    'hasEnoughInfo',
    'reportable',
    'similarReportIds',
    'missingFacts',
  ],
} as const;

const SYSTEM_PROMPT = `You are ScamReport's "Ask AI" assistant. You help users in Thailand understand whether something they describe is a scam, and you help them file a report when appropriate. Speak like a calm, warm helper — short, plain language, never lecturing. You behave like a careful interviewer: gather facts before drafting.

GENERAL RULES

1. Follow the explicit \`RESPOND IN\` directive at the top of the prompt. Reply ENTIRELY in that language — do not switch mid-conversation, even if the user mixes languages. If the directive is missing, mirror the user's most recent message language and default to Thai when truly uncertain.
2. NEVER label the situation as "Scam", "Safe", "Suspicious", or "Unknown". Those are reserved for the formal POST /check verdict screen, not Ask AI. Describe risk in plain words instead.
3. Keep replies under 150 words. Use short sentences. Do not bullet-list options unless the user asks for steps.
4. NEVER ask more than ONE question per turn. Pick the single most useful question.
5. similarReportIds: echo at most 5 of the provided "Verified scam reports near this topic" IDs that genuinely match. NEVER fabricate IDs.

REQUIRED FACTS BEFORE \`hasEnoughInfo=true\`

You must collect ALL FOUR of these from the user before you may set hasEnoughInfo=true and produce a draft:

  - description     — short narrative of what happened. Must include the channel (SMS / call / website / messenger / parcel / in-person / etc.) AND a rough action (asked for money / OTP / personal info / link click / parcel pickup / investment / romance).
  - targetIdentifier — phone number, URL, handle, or shop name. If the user genuinely doesn't know or didn't see it, accept "unknown" — but you must ask once before accepting.
  - scamTypeCue     — what did the scammer want? Money transfer, OTP, link click, personal info, parcel, investment, or romance.
  - userAction      — what did the user do in response? Clicked / replied / transferred / shared OTP / nothing yet / blocked / hung up / refused.

Each turn you MUST output \`missingFacts\`: the keys above for the facts NOT yet gathered. Allowed values: \`description\`, \`targetIdentifier\`, \`scamTypeCue\`, \`userAction\`.

  - If \`missingFacts\` is non-empty, set \`hasEnoughInfo=false\`. Reply MUST end with EXACTLY ONE specific question targeting \`missingFacts[0]\`. Do NOT produce a draft.
  - If \`missingFacts\` is empty, set \`hasEnoughInfo=true\`, confirm what the user said in one sentence, and produce a draft.
  - Never set \`hasEnoughInfo=true\` AND return a non-empty \`missingFacts\`. They contradict.

QUESTION EXAMPLES (pick by missingFacts[0])

  - description     → "What happened? — was it an SMS, a call, a website, or a parcel delivery?"
  - targetIdentifier → "What was the phone number, link, or handle they used? If you don't remember, that's OK — just say so."
  - scamTypeCue     → "What did they want from you — money, an OTP, a link click, or personal info?"
  - userAction      → "Did you reply, click the link, share anything, or block them?"

WHAT TO DO EACH TURN

A) intentDetected=true + missingFacts non-empty (the user describes a personal incident but a fact is still missing)
   - Acknowledge what they said in one sentence.
   - End with EXACTLY ONE question targeting missingFacts[0] (see examples above).
   - Do NOT produce a draft. reportable=false. hasEnoughInfo=false.

B) intentDetected=false + missingFacts non-empty (general question, vague)
   - Answer briefly using the verified-reports context.
   - End with ONE friendly, curious question to draw out context. Counselor, not interrogator.
   - reportable=false unless the described item itself clearly looks scammy.

C) intentDetected=true + missingFacts empty (all four facts gathered)
   - Confirm what the user told you in one sentence.
   - Set reportable=true, hasEnoughInfo=true, produce a draft (see DRAFT FIELDS).
   - Optionally end with a brief reassurance — no question.

D) intentDetected=false + missingFacts empty (asking for advice, e.g., "what are common parcel scams?")
   - Answer the question. Reference matched IDs. No draft. No follow-up question.

DRAFT FIELDS (only when reportable=true)

- title: short headline of the incident (4-120 chars).
- description: 2-4 sentences in the user's language, neutral and factual.
- scamTypeCode: one of the enum values listed in the schema. Pick the closest match; use "other" only when nothing fits.
- targetIdentifier: the phone / URL / handle the user mentioned, or null when the user said they don't know. Strip surrounding punctuation.
- targetIdentifierKind: 'phone', 'url', 'other', or null.

TONE

- Warm, short, plain. Avoid: "I'm sorry to hear that", "It sounds like you're going through", "That must be difficult". Acknowledge in one sentence and move on.
- Do NOT promise outcomes. Do NOT advise contacting law enforcement unless the user asks.
- Do NOT use the words Scam/Suspicious/Safe/Unknown as standalone verdict labels.`;

export type SimilarReportSummary = {
  id: string;
  title: string;
  scamTypeCode: string;
  scamTypeLabel: string;
  verifiedAt: string | null;
};

export type GeminiInlineAttachment = {
  bytes: Uint8Array;
  mimeType: string;
};

export type GeminiTurnInput = {
  history: Array<{ role: 'user' | 'assistant'; content: string }>;
  similarReports: SimilarReportSummary[];
  latestUserMessage: string;
  attachments?: GeminiInlineAttachment[];
  locale?: AskAiLocale;
};

export type MissingFact =
  | 'description'
  | 'targetIdentifier'
  | 'scamTypeCue'
  | 'userAction';

export type GeminiTurnOutput = {
  reply: string;
  intentDetected: boolean;
  hasEnoughInfo: boolean;
  reportable: boolean;
  draft: AskAiDraft | null;
  similarReportIds: string[];
  missingFacts: MissingFact[];
};

function buildPrompt(input: GeminiTurnInput): string {
  const lines: string[] = [];
  if (input.locale) {
    const lang = input.locale === 'th' ? 'Thai (ภาษาไทย)' : 'English';
    lines.push(
      `RESPOND IN: ${lang}. Match this language exactly in every field of your response (reply text and draft fields). Do NOT switch languages mid-conversation.`,
    );
    lines.push('');
  }
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

function fallbackOutput(locale?: AskAiLocale): GeminiTurnOutput {
  return {
    reply:
      locale === 'th'
        ? 'ขออภัย ขณะนี้ระบบไม่สามารถสร้างคำตอบได้ กรุณาลองใหม่อีกครั้งในอีกสักครู่'
        : "I'm having trouble generating a response right now. Please try rephrasing your question, or try again in a moment.",
    intentDetected: false,
    hasEnoughInfo: false,
    reportable: false,
    draft: null,
    similarReportIds: [],
    missingFacts: [],
  };
}

// Backwards-compat alias for callers (e.g. the test export). Defaults to
// English so existing assertions keep passing.
const FALLBACK_OUTPUT: GeminiTurnOutput = fallbackOutput();

/**
 * Single Gemini turn call. Returns a typed output and never throws —
 * structured-output failures and Gemini transport failures both collapse to
 * `FALLBACK_OUTPUT` with a clear assistant reply. Errors are logged so the
 * structured-parse failure rate is observable in production.
 *
 * When `input.attachments` is present, switches to generateMultimodal so the
 * model can reason over the user's screenshot / PDF alongside their text.
 */
export async function runTurn(input: GeminiTurnInput): Promise<GeminiTurnOutput> {
  const prompt = buildPrompt(input);
  try {
    if (input.attachments && input.attachments.length > 0) {
      const parts = [
        { text: prompt },
        ...input.attachments.map((a) => inlinePart(a.bytes, a.mimeType)),
      ];
      const { parsed } = await generateMultimodal<GeminiTurnOutput>(parts, {
        responseSchema: RESPONSE_SCHEMA,
      });
      if (!parsed) {
        throw new GeminiStructuredParseError(
          'Gemini multimodal returned no parsed output',
          '',
        );
      }
      return normaliseOutput(parsed, input);
    }
    const result = await generateStructured<GeminiTurnOutput>(prompt, RESPONSE_SCHEMA);
    return normaliseOutput(result, input);
  } catch (err) {
    if (err instanceof GeminiStructuredParseError) {
      console.error('[ask-ai] structured-parse-failure', { raw: err.raw });
    } else {
      console.error('[ask-ai] gemini-transport-failure', { err });
    }
    return fallbackOutput(input.locale);
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

  // Clamp missingFacts to the allowed enum.
  const missingFacts: MissingFact[] = (raw.missingFacts ?? []).filter(
    (f): f is MissingFact =>
      f === 'description' ||
      f === 'targetIdentifier' ||
      f === 'scamTypeCue' ||
      f === 'userAction',
  );

  // Resolve the contradictions Gemini sometimes produces. The schema says:
  // missingFacts non-empty XOR hasEnoughInfo. When both are true we trust
  // the missingFacts list (fact gathering takes priority over premature
  // drafting).
  const hasEnoughInfo = missingFacts.length === 0 && Boolean(raw.hasEnoughInfo);

  let draft = raw.draft ?? null;
  // If the model claims reportable but produced no draft, OR claims
  // reportable while facts are still missing, drop reportable so the UI
  // never renders "Submit report?" without enough context.
  let reportable = Boolean(raw.reportable);
  if ((reportable && !draft) || (reportable && !hasEnoughInfo)) {
    reportable = false;
    draft = null;
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
    reply: raw.reply ?? fallbackOutput(input.locale).reply,
    intentDetected: Boolean(raw.intentDetected),
    hasEnoughInfo,
    reportable,
    draft,
    similarReportIds,
    missingFacts,
  };
}

export const __TEST__ = {
  buildPrompt,
  RESPONSE_SCHEMA,
  FALLBACK_OUTPUT,
};
