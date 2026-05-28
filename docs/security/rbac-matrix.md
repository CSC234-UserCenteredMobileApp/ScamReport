# RBAC matrix & Firestore rules breakdown

> Cross-link from `docs/audit-report.md` §4. Authoritative source for which role can call which endpoint and which Firestore document.

## Roles

| Role | Source of truth | How it's resolved |
| --- | --- | --- |
| **guest** | (no row) | Anonymous client. No `Authorization` header. Limited to public endpoints. |
| **user** | `users.role = 'user'` in Postgres | Firebase ID token → `verifyIdToken` → server-side lookup of `users.role` (`apps/api/src/core/middleware/require_role.ts:37`). Firebase custom claims are intentionally **not** trusted. |
| **admin** | `users.role = 'admin'` in Postgres | Same lookup; promoted via a single SQL update. `admin` is a strict superset — any route that accepts `user` also accepts `admin` (`require_role.ts:79`). |

## Endpoint × role matrix

`✓` = allowed; `✗` = 401 (missing token) or 403 (wrong role). All admin routes use `.use(requireRole('admin'))`; all user routes use `.use(requireAuth)` or `.use(requireRole('user'))`; everything else is public.

| Endpoint | guest | user | admin | Source |
| --- | :---: | :---: | :---: | --- |
| `GET /health` | ✓ | ✓ | ✓ | `apps/api/src/features/health/health.route.ts` |
| `GET /stats` | ✓ | ✓ | ✓ | `apps/api/src/features/stats/stats.route.ts` |
| `GET /scam-types` | ✓ | ✓ | ✓ | `apps/api/src/features/scam-types/scam-types.route.ts` |
| `GET /announcements` | ✓ | ✓ | ✓ | `apps/api/src/features/announcements/announcements.route.ts:12` |
| `GET /announcements/:id` | ✓ | ✓ | ✓ | `apps/api/src/features/announcements/announcements.route.ts:56` |
| `POST /check` | ✓ | ✓ | ✓ | `apps/api/src/features/check/check.route.ts:9` |
| `GET /check/recent` | ✓ | ✓ | ✓ | `apps/api/src/features/check/check.route.ts:17` |
| `GET /reports` (verified feed) | ✓ | ✓ | ✓ | `apps/api/src/features/reports/reports.route.ts:29` |
| `GET /reports/:id` (public detail) | ✓ | ✓ | ✓ | `apps/api/src/features/reports/reports.route.ts:100` |
| `POST /auth/sync` | ✗ | ✓ | ✓ | `apps/api/src/features/auth/auth.route.ts:17` |
| `POST /reports` (submit) | ✗ | ✓ | ✓ | `apps/api/src/features/reports/reports.route.ts:169` (after `.use(requireAuth)` at line 168) |
| `POST /reports/:id/evidence` | ✗ | ✓ | ✓ | `apps/api/src/features/reports/reports.route.ts:208` |
| `GET /reports/mine` | ✗ | ✓ | ✓ | `apps/api/src/features/reports/reports.route.ts:231` |
| `GET /reports/mine/:id` | ✗ | ✓ | ✓ | `apps/api/src/features/reports/reports.route.ts:242` |
| `PATCH /reports/:id` (withdraw / edit) | ✗ | owner only | ✓ | `apps/api/src/features/reports/reports.route.ts:266` |
| `DELETE /reports/:id` | ✗ | owner only | ✓ | `apps/api/src/features/reports/reports.route.ts:292` |
| `POST /ask-ai/conversations` | ✗ | ✓ | ✓ | `apps/api/src/features/ask-ai/ask-ai.route.ts:38` (after `.use(requireAuth)`) |
| `GET /ask-ai/conversations` | ✗ | ✓ | ✓ | `ask-ai.route.ts:48` |
| `GET /ask-ai/conversations/:id` | ✗ | owner only | ✓ | `ask-ai.route.ts:58` |
| `DELETE /ask-ai/conversations/:id` | ✗ | owner only | ✓ | `ask-ai.route.ts:77` |
| `POST /ask-ai/conversations/:id/turns` | ✗ | owner only | ✓ | `ask-ai.route.ts:100` |
| `POST /ask-ai/conversations/:id/submit` | ✗ | owner only | ✓ | `ask-ai.route.ts:134` |
| `PATCH /ask-ai/turns/:id/feedback` | ✗ | owner only | ✓ | `ask-ai.route.ts:201` |
| `POST /me/notifications/devices` | ✗ | ✓ | ✓ | `apps/api/src/features/notifications/notifications.route.ts:21` (after `.use(requireAuth)`) |
| `DELETE /me/notifications/devices/:id` | ✗ | ✓ | ✓ | `notifications.route.ts:34` |
| `GET /me/notifications/preferences` | ✗ | ✓ | ✓ | `notifications.route.ts:54` |
| `POST /me/notifications/preferences` | ✗ | ✓ | ✓ | `notifications.route.ts:63` |
| `GET /admin/reports` (queue) | ✗ | ✗ | ✓ | `apps/api/src/features/admin-reports/admin-reports.route.ts:38` |
| `GET /admin/reports/:id` | ✗ | ✗ | ✓ | `admin-reports.route.ts:83` |
| `GET /admin/reports/:id/audit` | ✗ | ✗ | ✓ | `admin-reports.route.ts:95` |
| `GET /admin/reports/:id/pdf` | ✗ | ✗ | ✓ | `admin-reports.route.ts:108` |
| `POST /admin/reports/:id/approve` | ✗ | ✗ | ✓ | `admin-reports.route.ts:164` |
| `POST /admin/reports/:id/reject` | ✗ | ✗ | ✓ | `admin-reports.route.ts:183` |
| `POST /admin/reports/:id/flag` | ✗ | ✗ | ✓ | `admin-reports.route.ts:202` |
| `POST /admin/reports/:id/unflag` | ✗ | ✗ | ✓ | `admin-reports.route.ts:221` |
| `GET /admin/announcements` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-announcements/admin-announcements.route.ts:28` |
| `POST /admin/announcements` | ✗ | ✗ | ✓ | `admin-announcements.route.ts:61` |
| `PUT /admin/announcements/:id` | ✗ | ✗ | ✓ | `admin-announcements.route.ts:74` |
| `DELETE /admin/announcements/:id` | ✗ | ✗ | ✓ | `admin-announcements.route.ts:96` |
| `POST /admin/announcements/:id/publish` | ✗ | ✗ | ✓ | `admin-announcements.route.ts:121` |
| `GET /admin/scammers` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-scammers/admin-scammers.route.ts:21` |
| `POST /admin/scammers/:id/merge` | ✗ | ✗ | ✓ | `admin-scammers.route.ts:73` |
| `GET /admin/persons` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-persons/admin-persons.route.ts:11` |
| `GET /admin/notifications/jobs` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-notifications/admin-notifications.route.ts:6` |
| `GET /admin/platform-summary` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-platform-summary/admin-platform-summary.route.ts:8` |
| `GET /admin/scam-overview` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-scam-overview/admin-scam-overview.route.ts:6` |
| `GET /admin/ai-eval/latest` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-ai-eval/admin-ai-eval.route.ts:9` |
| `GET /admin/ai-eval/history` | ✗ | ✗ | ✓ | `admin-ai-eval.route.ts:14` |
| `GET /admin/exports/reports.csv` | ✗ | ✗ | ✓ | `apps/api/src/features/admin-exports/admin-exports.route.ts:23` |
| `GET /admin/exports/bundle` | ✗ | ✗ | ✓ | `admin-exports.route.ts:28` |

**Owner-only** rows mean the route is authenticated as `user`, but the handler additionally checks `report.reporterId === user.uid` (or equivalent `conversation.userId` for Ask AI) before serving the row. A user trying to read another user's draft, withdraw it, or post a turn into a stranger's conversation gets 404 (not 403, to avoid existence enumeration).

## Reporter anonymisation on admin endpoints

Every `/admin/*` response that includes report data strips reporter PII before serialisation: no `reporter_user_id`, `email`, `display_name`, `handle`, or `avatar_url`. Verified by `apps/api/test/admin-reports.test.ts` assertions on the response shape. Source: `SECURITY.md` "In-scope vulnerabilities" + PRD §FR-7.4 / FR-7.8.

## Firestore rules breakdown

`firestore.rules` is the entire policy — 43 lines. Three rules + a default deny:

| Path pattern | `allow read` | `allow write` | Why |
| --- | --- | --- | --- |
| `/alerts/{announcementId}` | `if true` (public) | `if false` | Announcements are public on Web + mobile and need offline reads. The mirror writer is `apps/api/src/sync/firestore_sync.ts::mirrorAlert(...)`, called inline at the end of every admin announcement mutation, using the Firebase Admin SDK (bypasses rules). Clients can never write. |
| `/my-reports/{uid}/items/{reportId}` | `if request.auth != null && request.auth.uid == uid` | `if false` | Per-user submission history. The path embeds the owner UID so the rule check is a single equality. Submission still goes through the API (PRD OQ-4 / FR-5.4), which writes the canonical record to Postgres and then mirrors here. The mirror writer also collapses the `flagged` status to `pending` for the reporter's view (PRD FR-6.1) so the user is never tipped off about an active moderation review. |
| `/{document=**}` (default) | `if false` | `if false` | Default-deny. Anything not explicitly matched above is rejected — defence-in-depth in case a future PR adds a collection without adding a corresponding rule. |

The two read surfaces above are the **entire** Firestore footprint. Postgres remains system of record for everything else: verified feed (P-03), report detail (P-04), Ask AI conversations (P-09 — needs `pgvector` for retrieval), moderation queue (A-01), admin review (A-02), and every mutation. See `docs/architecture.md` §"Firestore mirror".

## Canonical role journeys

**Guest** opens the app, lands on the verified feed, can `GET /reports` and `GET /announcements`, can run a `POST /check` against the rule-based scanner. Cannot submit a report (`POST /reports` → 401 → mobile redirects to `/login`), cannot read `/my-reports/{uid}/items` (Firestore rule rejects), cannot reach any `/admin/*` route.

**User** signs in with Firebase Auth, calls `POST /auth/sync` once to upsert the Postgres row. Can submit reports, see their own draft + verified history at `/reports/mine`, hold conversations with Ask AI, manage their FCM device tokens. Cannot read another user's reports (handler-level owner check + Firestore `uid` equality), cannot reach `/admin/*` (403).

**Admin** signs in the same way; the only difference is `users.role = 'admin'` in Postgres. Gains the entire `/admin/*` surface for moderation, announcements, scammer dedupe, persons review, AI-eval dashboards, CSV/bundle exports. Cannot bypass reporter anonymisation (the serializer drops PII before responses leave the server). Cannot write to Firestore directly — admin mutations go through the API, which writes Postgres and then mirrors.

**Service** (Firebase Admin SDK) is the only identity that ever writes to Firestore, and only from within the API process. Its credentials are never shipped to a client: the service-account JSON is `.gitignore`d and is read at server startup from `apps/api/.env`.
