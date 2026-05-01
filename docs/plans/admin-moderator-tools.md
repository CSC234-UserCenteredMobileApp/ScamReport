# Admin Moderator Tools — Feature Plan

> **Status:** Planned — Sprint 3 candidate (2026-05-07+)
> **UX/UI:** Screen designs for A-01, A-02, A-03 are pending update. Do not start mobile implementation until revised specs land in `docs/design/screens/`.
> **PRD coverage:** FR-7.1 – FR-7.8
> **Design specs:** `docs/design/screens/mod.md`, `docs/design/screens/admin-review.md`, `docs/design/screens/announcement-editor.md`
> **Build order:** API + shared schemas first → mobile screens second

---

## Context

Zero admin endpoints exist today. Infrastructure is ready:
- `requireRole('admin')` middleware — `apps/api/src/core/middleware/require_role.ts`
- Prisma models: `Report`, `ModerationAction`, `Announcement`, `ReportEmbedding`
- Gemini client — `apps/api/src/core/gemini/client.ts`
- pgvector + `report_embeddings` table — wired for semantic search; reused here for AI scoring

No mobile admin feature folders exist. No `/admin/*` or `/mod/*` routes exist.

---

## What we're building

### Core (PRD-required)

Three admin screens + their API contracts:

| Screen | PRD | Description |
|---|---|---|
| Mod queue | A-01 / FR-7.1 | List of pending + flagged reports, sorted by age |
| Admin review | A-02 / FR-7.3 | Full report view — approve / reject / flag with remark + audit trail |
| Announcement editor | A-03 / FR-7.7 | Create / edit / publish / unpublish announcements |

### Enhancements (lightweight, low risk)

| ID | Name | What it does | Cost |
|---|---|---|---|
| A | Remark templates | Preset chips above remark textarea: "Insufficient evidence", "Duplicate — already verified", "Not scam content", "Contains personal info", "Test/malformed". One tap pre-fills the field. | Client-side only. Zero API changes. ~1 widget + constants. |
| B | Duplicate identifier badge | `GET /admin/reports/:id` returns `duplicateCount` — count of verified reports with the same `target_identifier_normalized`. Shows banner on review screen if > 0. | One extra `COUNT` query in detail endpoint. One banner widget. |
| C | AI confidence score | On admin detail load, embed the pending report's `title + description` via Gemini `text-embedding-004`, query cosine similarity against verified `report_embeddings`, map top-3 avg similarity → `aiScore (0–100)` + `aiConfidence (high/medium/low/unknown)`. Shown as advisory badge — admin still decides. | Add `embed(text)` to Gemini client. `computeAiScore()` in service. ~300–500ms added to admin detail load. |

**Not building yet:** bulk approve/reject (transaction complexity + mobile multi-select adds ~1 day risk; revisit when queue volume justifies it).

---

## AI Scoring — detail

**How it works:**

1. Admin opens a report for review.
2. API embeds `title + description` on-demand using Gemini `text-embedding-004`.
3. Queries `report_embeddings` for top-5 cosine-similar verified reports.
4. Computes weighted average similarity of top-3 matches.
5. Maps to score + confidence label:

| Avg similarity | aiScore | aiConfidence |
|---|---|---|
| ≥ 0.85 | 85–100 | `high` |
| ≥ 0.70 | 60–84 | `medium` |
| < 0.70 | 0–59 | `low` |
| No verified embeddings | — | `unknown` |

**Important caveats:**
- Score is advisory only. Never displayed as a verdict. UI labels it "AI confidence".
- Score improves as the verified report pool grows. Early weeks will produce mostly `unknown`.
- Score is computed on-the-fly per request. Not persisted (avoids stale values as pool grows).
- Embeddings currently only exist for verified reports. Pending reports are not pre-embedded — this is intentional (avoids embedding every draft submission).

**What changes for AI scoring:**

| File | Change |
|---|---|
| `apps/api/src/core/gemini/client.ts` | Add `embed(text: string): Promise<number[]>` using `text-embedding-004` |
| `apps/api/src/features/admin-reports/admin-reports.service.ts` | Add `computeAiScore(titlePlusDescription: string)` |
| `packages/shared/src/schemas/admin-reports.ts` | Add `aiScore: number`, `aiConfidence` enum to `AdminReportDetail` + `AdminQueueItem` |
| Mobile review screen | AI confidence chip next to status |

---

## API endpoints

### Admin reports — `apps/api/src/features/admin-reports/`

| Method | Path | What it does |
|---|---|---|
| `GET` | `/admin/reports/queue` | Pending + flagged. Flagged first, then oldest pending. `?scam_type=` filter. Returns `{ items[], pendingCount, flaggedCount }`. No reporter fields. |
| `GET` | `/admin/reports/:id` | Full detail. No reporter fields. Includes `duplicateCount`, `aiScore`, `aiConfidence`, `auditTrail[]`. |
| `POST` | `/admin/reports/:id/approve` | Status → `verified`. Inserts `ModerationAction`. Sets `verifiedAt`. Firestore mirror. FCM push to reporter. |
| `POST` | `/admin/reports/:id/reject` | Status → `rejected`. Inserts `ModerationAction`. Sets `rejectionRemark`. FCM push to reporter. |
| `POST` | `/admin/reports/:id/flag` | Status → `flagged`. Inserts `ModerationAction`. |
| `POST` | `/admin/reports/:id/unflag` | Status → `pending`. Inserts `ModerationAction` (action: `unflag`). |

All action bodies: `{ remark: string }` (required, non-empty).

### Admin announcements — `apps/api/src/features/admin-announcements/`

| Method | Path | What it does |
|---|---|---|
| `GET` | `/admin/announcements` | All announcements (draft + published + unpublished), paginated. |
| `POST` | `/admin/announcements` | Create draft. |
| `PATCH` | `/admin/announcements/:id` | Edit title/body/category (draft or unpublished only). |
| `POST` | `/admin/announcements/:id/publish` | Status → `published`. Sets `publishedAt`. Body `{ sendPush: boolean }`. If `sendPush: true` and `pushedToFcmAt IS NULL`, broadcasts FCM + sets `pushedToFcmAt`. |
| `POST` | `/admin/announcements/:id/unpublish` | Status → `unpublished`. |
| `DELETE` | `/admin/announcements/:id` | Hard delete. Fails with 409 if `status = 'published'` (must unpublish first). |

---

## Shared schemas — `packages/shared/src/schemas/`

### `admin-reports.ts`

```ts
AdminQueueItem     // id, title, scamTypeCode, scamTypeLabelEn/Th, submittedAt,
                   // status, priorityFlag, evidenceCount, aiScore, aiConfidence

AdminReportDetail  // all AdminQueueItem fields + description, targetIdentifier,
                   // targetIdentifierKind, evidenceFiles[], duplicateCount,
                   // aiScore, aiConfidence, auditTrail[]
                   // !! NO reporterId / reporter / reporter.email / reporter.displayName

ModerationRecord        // adminId, action, remark, createdAt
ApproveRejectFlagRequest // { remark: string }
AdminActionResponse     // { id, status, updatedAt }
```

### `admin-announcements.ts`

```ts
AdminAnnouncementCard     // id, title, category, status, publishedAt, createdAt
AdminAnnouncementDetail   // above + body, pushedToFcmAt, updatedAt
CreateAnnouncementRequest // { title, body, category, status? }
UpdateAnnouncementRequest // Partial<Create>
PublishAnnouncementRequest // { sendPush: boolean }
```

Re-export both from `packages/shared/src/index.ts`.

---

## Files to create / modify

**New:**
```
packages/shared/src/schemas/admin-reports.ts
packages/shared/src/schemas/admin-announcements.ts
apps/api/src/features/admin-reports/admin-reports.route.ts
apps/api/src/features/admin-reports/admin-reports.service.ts
apps/api/src/features/admin-announcements/admin-announcements.route.ts
apps/api/src/features/admin-announcements/admin-announcements.service.ts
apps/api/test/admin-reports.test.ts
apps/api/test/admin-announcements.test.ts
apps/mobile/lib/features/moderation/domain/mod_report.dart
apps/mobile/lib/features/moderation/domain/mod_announcement.dart
apps/mobile/lib/features/moderation/data/mod_repository.dart
apps/mobile/lib/features/moderation/presentation/mod_screen.dart
apps/mobile/lib/features/moderation/presentation/admin_review_screen.dart
apps/mobile/lib/features/moderation/presentation/announcement_editor_screen.dart
apps/mobile/lib/features/moderation/presentation/mod_providers.dart
apps/mobile/test/features/moderation/mod_screen_test.dart
apps/mobile/test/features/moderation/admin_review_screen_test.dart
apps/mobile/test/features/moderation/announcement_editor_screen_test.dart
```

**Modified:**
```
packages/shared/src/index.ts                 — re-export admin schemas
apps/api/src/core/gemini/client.ts           — add embed(text) function
apps/api/src/index.ts                        — mount adminReportsRoute, adminAnnouncementsRoute
apps/mobile/lib/core/router/app_router.dart  — add /mod, /admin/review/:id,
                                               /admin/announcements/editor routes
```

---

## Mobile screens

### `mod_screen.dart` (A-01)
- Stats row: `pendingCount` / `flaggedCount` / avg age
- Sort: oldest-first default; scam type filter chip
- Queue rows: type chip + age badge + title + evidence count + `Review` button
- Flagged row variant: coral left-border + team note line (from `ModerationRecord.remark` of last flag action)
- Loading / empty (`Queue is empty — nice work!`) / error states
- Refreshes on screen focus; badge count on mod tab (FR-7.2)

### `admin_review_screen.dart` (A-02)
- Status + age meta
- Type chip + title + description
- Target identifier chip (if present)
- Evidence inline viewer
- **AI confidence chip** — `high`/`medium`/`low`/`unknown`; tooltip "AI similarity to known scams"
- **Duplicate banner** — shown if `duplicateCount > 0`
- Audit trail rows (chronological)
- Sticky action bar: `Reject` (red outlined) / `Flag` (amber outlined) / `Approve` (primary filled)
- Action → remark dialog (required)
- **Remark template chips** above textarea: "Insufficient evidence" / "Duplicate — already verified" / "Not scam content" / "Contains personal info" / "Test/malformed submission"

### `announcement_editor_screen.dart` (A-03)
- Category segmented chips (Fraud Alert / Tips / Platform Update)
- Title field (with character counter)
- Body field (multi-line; paragraphs + `• ` bullets)
- Push toggle: "Send as push notification" + subscriber count label
- Push toggle ON + Publish → confirm dialog "Send push to ~N users?"
- `Save draft` text button + `Publish` filled button (disabled until title + body + category set)
- Published state: `Publish` replaced by `Unpublish`

---

## Reporter anonymity checklist (FR-7.8)

These must be verified on every admin-facing PR by the `security-reviewer` agent:

- [ ] Prisma queries use `select` / `omit` to exclude `reporterId`, `reporter`, and all reporter relation fields
- [ ] No `reporter.*` key present in any admin response JSON (assert in tests)
- [ ] Audit trail shows `adminId` only (the admin who acted), never the reporter
- [ ] Evidence file signed URLs do not expose the reporter's user ID in the storage path

---

## Verification

1. `bun run typecheck` passes
2. `bun --filter @my-product/api test` covers:
   - Queue: only pending + flagged returned; sorted flagged-first then oldest
   - Reporter fields absent from all admin responses
   - Approve/reject/flag: `ModerationAction` row inserted, `reports.status` updated
   - FCM mock called on approve and reject (not on flag)
   - Announcement publish: `publishedAt` set; second publish does not re-fire FCM
   - Non-admin → 403; unauthenticated → 401
3. `flutter analyze` clean
4. Widget tests: mod queue (empty / loaded / error), admin review (pending / flagged / already-actioned / AI score states), announcement editor (draft / publish-disabled / published)
5. Manual smoke: admin signs in → mod queue loads → approve report → reporter's My Reports shows `Verified` → FCM push visible in server logs
