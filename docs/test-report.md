# ScamReport — Test Coverage Report

**Generated:** 2026-05-13  
**Branch:** main  
**Commit:** 559a9da

---

## Executive Summary

| Layer | Test Files | Tests | Coverage | Threshold | Status |
|---|---|---|---|---|---|
| Mobile (Flutter) | 61 | 439 | 81.04% | 80% | ✅ Pass |
| API (Elysia/Bun) | 22 | 176 | — | None set | — |
| Shared schemas (TypeBox) | 4 | 60 | — | None set | — |
| Web admin (React/Vitest) | 10 | 37 | 91.7% | 80% | ✅ Pass |
| **Total** | **97** | **712** | | | |

---

## Mobile (Flutter)

**Framework:** `flutter_test` + `mocktail`  
**Run:** `flutter test --coverage` (from `apps/mobile/`)  
**Coverage:** 81.04% line coverage (3,068 / 3,786 lines) — ✅ exceeds 80% threshold  
**Coverage file:** `apps/mobile/coverage/lcov.info`

### Test Type Breakdown

| Type | Count | % |
|---|---|---|
| Unit | 258 | 59% |
| Widget (smoke/visual) | 181 | 41% |
| **Total** | **439** | |

> Widget tests verify rendering only (no behavioral assertions); unit tests cover data, domain, and provider layers.

### Core Layer

| File | Tests | Type | What It Tests |
|---|---|---|---|
| `test/core/api_client_test.dart` | 2 | Unit | Base URL resolution, HTTP client provider lifecycle |
| `test/core/di/notifications_test.dart` | 1 | Unit | Notifications DI provider initialization |
| `test/core/services/notification_service_test.dart` | 5 | Unit | Local notification schedule, dismiss, replace |
| `test/core/theme/app_theme_test.dart` | 4 | Unit | Theme data & VerdictPalette color generation |
| `test/core/widgets/ai_score_card_test.dart` | 0 | Widget | AI score card rendering |
| `test/core/widgets/alert_card_test.dart` | 0 | Widget | Alert card (fraud/tips categories) |
| `test/core/widgets/app_shell_test.dart` | 0 | Widget | Bottom navigation scaffold |
| `test/core/widgets/audit_trail_row_test.dart` | 0 | Widget | Audit trail row |
| `test/core/widgets/mod_queue_row_test.dart` | 0 | Widget | Moderation queue row |
| `test/core/widgets/report_card_test.dart` | 0 | Widget | Report card |
| `test/l10n/app_localizations_test.dart` | 35 | Unit | Thai/English strings, ICU parameters, pluralization |

### Feature Layer

| Feature | File | Tests | Type | What It Tests |
|---|---|---|---|---|
| **alerts** | `test/features/alerts/alerts_repository_test.dart` | 12 | Unit | Fetch & cache alerts, remote sync |
| | `test/features/alerts/alerts_screen_test.dart` | 0 | Widget | Alerts list UI |
| | `test/features/alerts/announcement_detail_screen_test.dart` | 0 | Widget | Announcement detail UI |
| **ask_ai** | `test/features/ask_ai/ask_ai_api_client_test.dart` | 22 | Unit | Auth, conversations, messages, attachments, streaming |
| | `test/features/ask_ai/chat_controller_test.dart` | 12 | Unit | Chat state: send, receive, draft handling |
| | `test/features/ask_ai/entities_test.dart` | 8 | Unit | ChatMessage, Conversation, AiDraft entity logic |
| | `test/features/ask_ai/optimistic_send_test.dart` | 4 | Unit | Optimistic send & rollback on error |
| | `test/features/ask_ai/persistence_test.dart` | 11 | Unit | Drift DB: drafts, cache entries |
| | `test/features/ask_ai/redraft_preservation_test.dart` | 5 | Unit | Redraft state after navigation |
| | `test/features/ask_ai/reports_submit_api_test.dart` | 15 | Unit | Submit scam report from chat context |
| | `test/features/ask_ai/repository_impl_test.dart` | 7 | Unit | Conversation lifecycle, message syncing |
| | `test/features/ask_ai/send_turn_test.dart` | 4 | Unit | Message turn & response handling |
| | `test/features/ask_ai/ask_ai_screen_test.dart` | 0 | Widget | Chat UI: bubbles, composer, empty state |
| | `test/features/ask_ai/attachment_chip_test.dart` | 0 | Widget | Attachment chip |
| | `test/features/ask_ai/bubble_attachment_test.dart` | 0 | Widget | Message bubble with attachment |
| | `test/features/ask_ai/consent_card_test.dart` | 0 | Widget | Consent disclosure card |
| | `test/features/ask_ai/conversations_drawer_test.dart` | 0 | Widget | Conversations sidebar drawer |
| | `test/features/ask_ai/draft_editor_sheet_test.dart` | 0 | Widget | Draft editor bottom sheet |
| | `test/features/ask_ai/widgets/similar_report_card_test.dart` | 0 | Widget | Similar report card |
| **auth** | `test/features/auth/auth_api_test.dart` | 4 | Unit | User sync, token refresh, credential handling |
| | `test/features/auth/auth_providers_test.dart` | 2 | Unit | Auth Riverpod state providers |
| | `test/features/auth/auth_repository_test.dart` | 4 | Unit | Email sign-in, sign-out, token management |
| | `test/features/auth/auth_user_test.dart` | 3 | Unit | AuthUser entity & role validation |
| **call_screening** | `test/features/call_screening/call_screening_api_client_test.dart` | 4 | Unit | Fetch statuses, report calls |
| | `test/features/call_screening/call_screening_providers_test.dart` | 6 | Unit | Riverpod state providers |
| | `test/features/call_screening/call_screening_repository_test.dart` | 4 | Unit | Fetch & cache call screening data |
| | `test/features/call_screening/call_screening_screen_test.dart` | 0 | Widget | Call screening list UI |
| **check** | `test/features/check/check_api_client_test.dart` | 13 | Unit | Phone/email verify, scam detection |
| | `test/features/check/check_input_screen_test.dart` | 0 | Widget | Check input form |
| | `test/features/check/verdict_screen_test.dart` | 0 | Widget | Verdict result screen |
| **feed** | `test/features/feed/feed_repository_test.dart` | 3 | Unit | Fetch & cache reports feed |
| | `test/features/feed/feed_screen_test.dart` | 0 | Widget | Feed list UI |
| **home** | `test/features/home/home_api_test.dart` | 8 | Unit | Stats, alerts, reports endpoints |
| | `test/features/home/home_repository_test.dart` | 7 | Unit | Fetch home stats, alerts, reports with caching |
| | `test/features/home/home_screen_test.dart` | 0 | Widget | Home layout & stat cards |
| **legal** | `test/features/legal/legal_screen_test.dart` | 0 | Widget | Legal/ToS screen |
| **moderation** | `test/features/moderation/mod_repository_test.dart` | 15 | Unit | Fetch queue, report actions, user management |
| | `test/features/moderation/mod_providers_test.dart` | 5 | Unit | Moderation Riverpod providers |
| | `test/features/moderation/admin_review_screen_test.dart` | 0 | Widget | Admin review modal |
| | `test/features/moderation/mod_screen_test.dart` | 0 | Widget | Moderation queue screen |
| **reports** | `test/features/reports/report_detail_screen_test.dart` | 0 | Widget | Report detail view |
| **search** | `test/features/search/search_api_test.dart` | 9 | Unit | Query parsing, filtering, pagination |
| | `test/features/search/search_repository_test.dart` | 6 | Unit | Results caching & filter state |
| | `test/features/search/filter_bottom_sheet_test.dart` | 0 | Widget | Search filter sheet |
| | `test/features/search/search_screen_test.dart` | 0 | Widget | Search UI & results |
| **settings** | `test/features/settings/settings_repository_test.dart` | 8 | Unit | Persist to SharedPreferences/SecureStorage |
| | `test/features/settings/settings_providers_test.dart` | 3 | Unit | Theme, language providers |
| | `test/features/settings/settings_screen_sms_test.dart` | 0 | Widget | SMS scan toggle UI |
| **sms_scan** | `test/features/sms_scan/data/sms_scan_repository_test.dart` | 7 | Unit | Detection & local persistence |
| | `test/features/sms_scan/presentation/sms_overlay_banner_test.dart` | 0 | Widget | SMS notification banner |

### Mocking Strategy

| Mock | Used In |
|---|---|
| `FirebaseAuth`, `User` | Auth tests |
| `AuthApi`, `AskAiApiClient` | API endpoint tests |
| `http.MockClient` | HTTP response stubbing |
| `http.StreamedResponse` | Streaming API responses |
| Riverpod `ProviderContainer` | DI isolation |

---

## API (Elysia/Bun)

**Framework:** `bun:test` (native)  
**Run:** `bun test` (from `apps/api/`)  
**Coverage:** LCOV files generated; no enforced threshold  
**Coverage file:** `apps/api/coverage/*.lcov.info.*.tmp` (last run: 2026-05-10)

All 22 test files are **integration tests** — routes tested end-to-end via `app.handle(new Request(...))` with mocked external services.

### Mocking Strategy

All tests use `mock.module()` to stub:

| Module | Stub |
|---|---|
| `firebase-admin/auth`, `firebase-admin/messaging` | Token verification, FCM |
| `src/core/db/client` | Prisma ORM |
| `src/core/gemini/client` | Gemini AI SDK |
| `src/core/supabase/storage` | File uploads |

### Public Endpoints

| File | Tests | Endpoint | What It Tests |
|---|---|---|---|
| `test/health.test.ts` | 1 | `GET /health` | Response shape `{ ok: true }` |
| `test/stats.test.ts` | 1 | `GET /stats` | Public aggregate counts |
| `test/auth.test.ts` | 3 | `POST /auth/sync` | Firebase token verify, user upsert, 401 on missing/invalid token |
| `test/announcements.test.ts` | 6 | `GET /announcements` | Public listing, pagination |
| `test/reports.test.ts` | 8 | `GET /reports`, `GET /reports/:id` | List limits, detail, signed URLs, reporter redaction |
| `test/reports-post.test.ts` | 16 | `POST /reports` | Creation, scam type validation, evidence (5-file limit), identifier normalization |
| `test/reports-search.test.ts` | 10 | `GET /reports/search` | Full-text search, keyword filtering, relevance |
| `test/reports-promote-evidence.test.ts` | 4 | `PUT /reports/:id/evidence/:fileId/promote` | Permission checks, evidence reordering |
| `test/check.test.ts` | 3 | `GET /check` | Query param validation |
| `test/check-post.test.ts` | 13 | `POST /check` | Schema validation, RAG+AI scoring, verdict resolution (scam/suspicious/safe/unknown) |
| `test/user.test.ts` | 6 | `GET /user` | Firebase token → Prisma user sync, role resolution |

### Ask-AI Endpoints

| File | Tests | Endpoint | What It Tests |
|---|---|---|---|
| `test/ask-ai.test.ts` | 24 | `/ask-ai/conversations/*` | Conversation lifecycle (create/list/get/delete), multipart upload, 30/day rate limit, 10MB attachment limit, MIME validation |
| `test/ask-ai-draft.test.ts` | 8 | `POST .../messages` | Reportable flag, draft proposal generation |
| `test/ask-ai-locale.test.ts` | 5 | Conversation messages | Language/locale handling in AI responses |

### Admin Endpoints

| File | Tests | Endpoint | What It Tests |
|---|---|---|---|
| `test/admin-announcements.test.ts` | 11 | `POST/PUT/DELETE /admin/announcements` | Admin role gating, full CRUD |
| `test/admin-reports.test.ts` | 24 | `GET/PUT /admin/reports/*` | Role verification, queue/detail views, AI scores, audit trail |
| `test/admin-deletion-requests.test.ts` | 9 | `POST /admin/deletion-requests` | Deletion flow, role checks, soft-delete auditing |

### Infrastructure / Middleware

| File | Tests | Area | What It Tests |
|---|---|---|---|
| `test/require_role.test.ts` | 8 | Middleware | Firebase token → Prisma role lookup, 403 when role absent |
| `test/cors.test.ts` | 4 | CORS | Allowlist: `localhost:5173`, `scamreport-admin.vercel.app`, preview domains; reject unknown origins |
| `test/firestore-sync.test.ts` | 8 | Sync | Firestore ↔ Postgres bidirectional sync (`POST /_sync/*`) |
| `test/identifier-extractor.test.ts` | 14 | Unit | `extractIdentifiers()`, `normalizePhone()`, `normalizeUrl()` — Thai E.164, URL hostname, deduplication |
| `test/ai-score.test.ts` | 10 | Unit | Gemini score tiers (high/medium/low/unknown), distribution 0–100 |

---

## Shared Schemas (TypeBox — `packages/shared`)

**Framework:** `bun:test`  
**Run:** `bun test` (from `packages/shared/`)  
**Coverage file:** `packages/shared/coverage/lcov.info`

All 4 files use `Value.Check()` with registered format validators (`uuid`, `date-time`).

| File | Tests | Schema(s) | What It Tests |
|---|---|---|---|
| `test/check.test.ts` | 14 | `CheckRequest`, `CheckResponse` | Request types (phone/url/text), verdicts (scam/suspicious/safe/unknown), match shape, optional meta |
| `test/reports.test.ts` | 17 | `CreateReportRequest`, `CreateReportResponse`, `EvidenceUploadResponse` | Evidence file limits (0–5), scam type codes, target identifier+kind pairs, conversation linkage |
| `test/ask-ai.test.ts` | 20 | `AiConversationRequest`, `AiMessageRequest`, `AiConversationResponse` | Message content, attachment metadata shape, reportable flag |
| `test/admin-reports.test.ts` | 9 | `AdminQueueItem`, `AdminReportDetail`, `AiConfidence` | AI score range (0–100), confidence enum, reporter redaction, null-score legacy support |

---

## Web Admin Portal (React/Vitest — `apps/web`)

**Framework:** Vitest 2.1.2 + React Testing Library + MSW  
**Run:** `bun test` (from `apps/web/`)  
**Coverage:** 91.7% line coverage (564/615 lines) — ✅ exceeds 80% threshold  
**Coverage file:** `apps/web/coverage/coverage-summary.json`  
**Last run:** 2026-05-13

### Coverage Thresholds

| Metric | Threshold | Actual | Status |
|---|---|---|---|
| Lines | 80% | 91.7% | ✅ |
| Statements | 80% | ~91% | ✅ |
| Functions | 70% | 81.25% | ✅ |
| Branches | 70% | 87.76% | ✅ |

### Test Type Breakdown

| Type | Count | % |
|---|---|---|
| Unit | ~18 | 50% |
| Component | ~13 | 35% |
| Integration | ~6 | 15% |
| **Total** | **~37** | |

### Library Tests (`test/lib/`)

| File | Tests | Component | What It Tests |
|---|---|---|---|
| `test/lib/api-client.test.ts` | 6 | `lib/api/client.ts` | Authorization header attachment, 401/403/500 handling, TypeBox validation |
| `test/lib/auth-context.test.tsx` | 4 | `lib/auth/auth-context.tsx` | Auth hydration, `/auth/sync` role fetch, 401 fallback |
| `test/lib/query-keys.test.ts` | 4 | `lib/api/query-keys.ts` | Stable key generation (queue, detail, scam-type filter) |
| `test/lib/role-gate.test.tsx` | 4 | `lib/auth/role-gate.tsx` | Loading state, 401→login redirect, RBAC (user→no-access, admin→allowed) |
| `test/lib/utils.test.ts` | 2 | `lib/utils.ts` | `cn()` class merging, deduplication, falsy values |
| `test/lib/validators.test.ts` | 4 | `lib/api/validators.ts` | TypeBox precompiled checkers: adminQueue, authSync, adminAction |

### Feature Tests (`test/features/`)

| File | Tests | Component | What It Tests |
|---|---|---|---|
| `test/features/queue.test.ts` | 3 | `features/moderation/api/queue.ts` | `buildQueuePath()`: bare, query-encoded, special chars |
| `test/features/use-action-dialog.test.ts` | 3 | `features/moderation/hooks/use-action-dialog.ts` | Initial closed state, open with item+kind, close persistence |
| `test/features/actions.test.tsx` | 3 | `features/moderation/api/actions.ts` | Optimistic approve update, 500 rollback, flag toggle |
| `test/features/queue-page.test.tsx` | 4 | `features/moderation/pages/queue-page.tsx` | Full page render, empty state, error alert, action dialog + remark validation |

### Coverage by Module

| Module | Lines | Functions | Branches |
|---|---|---|---|
| `lib/api/client.ts` | 100% | 100% | 94.4% |
| `lib/auth/auth-context.tsx` | 98.4% | 100% | 82.4% |
| `lib/auth/role-gate.tsx` | 93.1% | 100% | 87.5% |
| `lib/api/validators.ts` | 100% | N/A | 100% |
| `features/moderation/api/queue.ts` | 100% | 100% | 100% |
| `features/moderation/api/actions.ts` | 94.4% | 100% | 69.2% |
| `features/moderation/components/queue-table.tsx` | 99.1% | 82.4% | 91.3% |
| `features/moderation/components/action-dialog.tsx` | 100% | 50% | 100% |
| `features/moderation/pages/queue-page.tsx` | 81.8% | 25% | 100% |
| `routes/sync-error.tsx` | 7.1% | 0% | N/A |

### Mocking Strategy

| Mock | Tool | What It Covers |
|---|---|---|
| HTTP requests | MSW | All `apiFetch()` calls; unhandled requests fail the test |
| Firebase Auth | Manual mock | `currentUser`, `onAuthStateChanged`, signin/signout |
| React Query | `QueryClient` fixture | Cache seeding, optimistic mutation verification |

### MSW Default Handlers

| Handler | Response |
|---|---|
| `POST /auth/sync` | Admin user profile |
| `GET /admin/reports/queue` | 2-item queue (pending + flagged) |
| `POST /admin/reports/:id/approve` | Action response |
| `POST /admin/reports/:id/reject` | Action response |
| `POST /admin/reports/:id/flag` | Action response |
| `POST /admin/reports/:id/unflag` | Action response |

---

## How to Run Tests

### All Tests (from repo root)

```bash
bun run test
```

Runs in order: API → Shared → Web → Mobile.

### Per Layer

| Layer | Command | Working Directory |
|---|---|---|
| Mobile (all) | `flutter test --coverage` | `apps/mobile/` |
| Mobile (single file) | `flutter test test/features/home/home_api_test.dart` | `apps/mobile/` |
| Mobile (pattern) | `flutter test --name="auth"` | `apps/mobile/` |
| API | `bun test` | `apps/api/` |
| Shared | `bun test` | `packages/shared/` |
| Web | `bun test` | `apps/web/` |
| Web (watch) | `bun test:watch` | `apps/web/` |

### Coverage Reports

| Layer | Command | Output Location |
|---|---|---|
| Mobile | `flutter test --coverage` | `apps/mobile/coverage/lcov.info` |
| Web | `bun test` (coverage included) | `apps/web/coverage/` |
| API | `bun test --coverage` | `apps/api/coverage/` |
| Shared | `bun test --coverage` | `packages/shared/coverage/` |

---

## Observations & Coverage Gaps

### Strengths

- **Mobile coverage consistently above 80%** — May 4: 80.5% → May 13: 81.04%, enforced as CI gate
- **Web coverage at 91.7%** — strong component + integration testing with MSW
- **Ask-AI most tested feature** — 88 mobile + 24 API + 20 shared = 132 tests across all layers
- **CORS allowlist tested** — prevents accidental origin expansion on admin portal
- **Optimistic updates verified** — both mobile (ask_ai) and web (moderation actions) test rollback on failure
- **Thai localization** — 35 dedicated tests for ICU parameters and pluralization edge cases
- **Contract-first schemas validated** — all 4 TypeBox schemas have dedicated unit tests before API or mobile consume them

### Known Gaps

| Gap | Layer | Notes |
|---|---|---|
| No integration tests | Mobile | No `integration_test/` directory; only unit + widget |
| Widget tests are smoke-only | Mobile | 181 widget tests have 0 behavioral assertions; render-only |
| API coverage threshold not enforced | API | LCOV generated but no `--coverage-threshold` flag in test config |
| Real DB/Firebase/Gemini not exercised | API | All external services mocked; no E2E against live infra |
| Sync-error screen low coverage | Web | 7.14% — intentional; error-path UI only triggered by runtime failure |
| Shared schema CI gate absent | Shared | No coverage threshold; TypeBox structure validated but no line gate |
