# Ask AI — File Attachment Support

> **Status:** Ready to implement
> **Scope:** Schema only (Prisma + docs update). API layer and mobile UI are separate tasks — see "Out of scope" section.
> **Depends on:** `ai_conversations` + `ai_messages` already in `prisma/schema.prisma` (done)
> **PRD ref:** FR-4.2, FR-4.5 (PRD v1.3 §3.3 — Ask AI feature)

---

## Context

The Ask AI chat (P-09) lets users describe scam incidents conversationally. Users need to attach evidence — screenshots of scam messages, LINE screenshots, fake transfer receipts — so Gemini can read and reason over them alongside the text conversation.

**Gemini supports multimodal input:** images (JPEG, PNG, WEBP, GIF) and PDFs can be passed inline or via the Gemini Files API. The DB only stores file metadata; bytes live in Supabase Storage.

Current `ai_messages` table has no attachment support. This plan adds it.

---

## Limits (enforced at API layer, documented here for reference)

| Constraint | Value | Reason |
|---|---|---|
| Max file size | 10 MB per file | Gemini inline data cap is 20 MB; 10 MB is safe for mobile uploads |
| Max attachments per message | 3 | Keeps context window manageable |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `application/pdf` | Gemini multimodal supported types |

---

## Step 1 — Edit `apps/api/prisma/schema.prisma`

### 1a. Add relation to existing `AiMessage` model

Find this block in the `AiMessage` model:

```prisma
  conversation AiConversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)

  @@index([conversationId, createdAt(sort: Asc)])
  @@map("ai_messages")
```

Replace with:

```prisma
  conversation AiConversation      @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  attachments  AiMessageAttachment[]

  @@index([conversationId, createdAt(sort: Asc)])
  @@map("ai_messages")
```

### 1b. Add new model (append after the `AiMessage` model)

```prisma
/// File attachment on an Ask AI message. Bytes live in Supabase Storage. (DESIGN §4.11)
model AiMessageAttachment {
  id          String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  messageId   String   @map("message_id") @db.Uuid
  storagePath String   @unique @map("storage_path")
  mimeType    String   @map("mime_type")
  sizeBytes   BigInt   @map("size_bytes")
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz()

  message AiMessage @relation(fields: [messageId], references: [id], onDelete: Cascade)

  @@map("ai_message_attachments")
}
```

**`storagePath` format:** `chat-attachments/{conversation_id}/{uuid}.{ext}`
Example: `chat-attachments/3f2a.../a1b2c3.jpg`

---

## Step 2 — Regenerate Prisma client

```bash
bun run prisma:generate
```

Expected output: `✔ Generated Prisma Client ... in Xms`

---

## Step 3 — Verify typecheck

```bash
bun run typecheck
```

Both `@my-product/shared` and `@my-product/api` must exit with code 0.

---

## Step 4 — Update `DATABASE_DESIGN.md`

In `DATABASE_DESIGN.md` §4.11, after the `ai_messages` table spec, add:

### `ai_message_attachments`

File metadata for attachments on user messages. Bytes live in Supabase Storage bucket `chat-attachments/`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `message_id` | `uuid` FK → `ai_messages(id)` ON DELETE CASCADE | |
| `storage_path` | `text` UNIQUE NOT NULL | `chat-attachments/{conversation_id}/{uuid}.ext` |
| `mime_type` | `text` NOT NULL | One of: `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `application/pdf` |
| `size_bytes` | `bigint` NOT NULL | Max 10 MB enforced at API layer |
| `created_at` | `timestamptz` NOT NULL DEFAULT `now()` | |

**Limits (enforced at API layer):** max 3 attachments per message, max 10 MB per file, allowed MIME types listed above.

Also update the §0 changelog to add a v1.4 entry:

```
| Area | v1.3 | v1.4 | Why |
|---|---|---|---|
| Ask AI attachments | No attachment support on ai_messages | Added `ai_message_attachments` table | PRD v1.3 FR-4.2: Gemini multimodal — users can attach screenshots/PDFs to Ask AI chat |
```

And update the document version header from `1.3` to `1.4`.

---

## Step 5 — Provision Supabase Storage bucket (manual)

In the Supabase dashboard for the project:

1. Go to **Storage** → **New bucket**
2. Name: `chat-attachments`
3. Public: **No** (private — files are served via signed URLs only)
4. File size limit: `10485760` (10 MB in bytes)
5. Allowed MIME types: `image/jpeg, image/png, image/webp, image/gif, application/pdf`

**RLS policy (add after bucket creation):**
- Authenticated users can INSERT into `chat-attachments/{their_user_id}/` paths
- Users can SELECT (via signed URL) their own conversation attachments
- Admins can SELECT all
- No public access

> Note: This is a console step, not in code. Same pattern as the `evidence` bucket (already provisioned).

---

## Out of scope (separate tasks)

These are **not** part of this plan. Do not implement until the Ask AI UX/UI spec (`docs/design/screens/ask-ai.md`) is confirmed:

| Task | Where it goes |
|---|---|
| API route: accept multipart upload, validate MIME + size, write to Supabase Storage, insert `ai_message_attachments` row | `apps/api/src/features/ask-ai/` |
| API: pass attachment bytes/URL to Gemini multimodal request | `apps/api/src/features/ask-ai/ask-ai.service.ts` |
| Mobile: file picker in chat input, upload progress, attachment preview chips | `apps/mobile/lib/features/ask_ai/presentation/` |
| Shared schema: update `AiMessageRequest` / `AiMessageResponse` TypeBox types | `packages/shared/src/schemas/ask-ai.ts` |

---

## Verification checklist

- [ ] `bun run prisma:generate` exits 0
- [ ] `bun run typecheck` exits 0
- [ ] `AiMessageAttachment` model visible in `apps/api/src/generated/prisma/models/`
- [ ] `AiMessage` model has `attachments` relation in generated client
- [ ] `DATABASE_DESIGN.md` updated to v1.4
- [ ] `chat-attachments` bucket provisioned in Supabase dashboard
