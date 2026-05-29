# User Journey Map — ScamReport

> CSC234 D4 deliverable. Maps each primary persona's end-to-end journey
> across the ScamReport mobile + web surfaces. Personas sourced from
> `docs/presentation.md` §"Slide 5 — Target Users & Personas". Screen
> evidence linked to per-screen specs under `docs/design/screens/` and
> design tokens in `docs/design-review.md`.

## Personas at a glance

| ID | Persona | Goal | Tech comfort | Primary device |
| --- | --- | --- | --- | --- |
| P1 | **Aunty Som**, 58, Bangkok | Check a suspicious "tax refund" SMS before tapping a link. Reads Thai only. | low | Android phone |
| P2 | **Tee**, 24, university student | Got scammed once. Wants to warn others + look up sellers before transferring money. | high | Android phone + occasional Web on a campus PC |
| P3 | **Khun Wirat**, NGO moderator | Triages 50–100 community reports per day from a desktop. | medium-high | Web admin portal |

## Stage legend

- **Trigger** — the external event that pulls the user into the app.
- **Action** — what the user does step-by-step.
- **Touchpoint** — which screen + which backing system/feature flag.
- **Emotion** — affective state, in 1–2 words.
- **Pain** — what could break the journey.
- **Opportunity** — design / product follow-up that would smooth the journey.

---

## P1 — Aunty Som · "Check before I click"

**Frame:** Aunty Som receives a Thai-language SMS claiming a tax refund and asking her to log into a short URL. She has heard her friends mention "the ScamReport app" and decides to verify before clicking.

| # | Stage | Action | Touchpoint | Emotion | Pain | Opportunity |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Trigger** | SMS arrives, looks plausible (gov-branded sender, money mentioned). | n/a — out of app | Anxious / curious | Phishing pretext is realistic. Aunty is the target demographic. | (out of scope) Carrier-side SMS labelling. |
| 2 | **Entry** | Long-press SMS → "Share" → picks "ScamReport — Check". | OS share sheet → mobile `ShareIntentListener` (`features/share_intent/`) | Hopeful | Share target only enabled when `enable_share_target` flag = true (`feature_flags.dart`). If off, Aunty types into the app instead. | Default the flag to **on** for `th` locale once telemetry shows zero crashes. |
| 3 | **Home land** | App opens to Home with the shared text pre-filled in a banner. UI is in Thai (default locale). | Home screen (`features/home/presentation/home_screen.dart`) → `_ClipboardBanner` | Reassured | If Firebase init fails, default locale could fall back to en. Mitigated by `core/di/firebase.dart` returning false gracefully + app default `th` from `SettingsState.defaults` (`apps/mobile/CLAUDE.md` "Localisation"). | Persist last-seen locale in `SharedPreferences` so a cold-boot doesn't surprise her. |
| 4 | **Check** | Taps **ตรวจสอบ** (Check) → URL/phone/text scanner returns a verdict pill. | Check screen → `POST /check` → AI verdict ("scam" / "suspicious" / "safe" / "unknown") + RAG context | Relieved / confirmed | If `enable_ask_ai` flag is off in prod, Check falls back to the rule-based scanner only, which has lower recall on novel pretexts. | Show a tiny "based on N similar reports" caption so the verdict feels grounded, not magical. |
| 5 | **Read verdict** | Sees red **VerdictPill: scam** banner + Thai explanation + 3 recent matching reports. Each report shows "verified" badge. | `VerdictPill` widget (light theme) + `ReportCard` list. Both rendered from Firestore mirror, so this still works on her capped data plan. | Empowered | Verdict copy must be plain Thai, not jargon. Verified by per-screen Thai review in `docs/design/screens/verdict.md`. | Add audio readback for low-literacy elders (out of v1). |
| 6 | **Act** | Closes the SMS without tapping. Optionally taps **"Report"** to add hers to the community evidence pool. | Submit Report flow (`features/reports/presentation/`) | Proud / civic | Submit requires login. Guest sees a redirect to `/login`. Friction = drop-off. | Allow anonymous reports with reduced trust weight; promote to verified after login. |
| 7 | **Follow up** | Receives a push 2 days later: "Your report was verified — visible in the public feed." | FCM (`firebase_messaging`) + `/me/notifications/preferences` | Validated | If she never granted FCM permission, no callback. App requests at startup (`initializeFirebase`) — fine on Android, requires explicit permission on iOS (out of scope). | Defer permission ask to after first successful report. |

---

## P2 — Tee · "Warn others, look up sellers"

**Frame:** Tee got scammed three months ago and follows scam-watcher Twitter accounts. He installs ScamReport to (a) report his old incident, (b) look up sellers before Facebook Marketplace deals.

| # | Stage | Action | Touchpoint | Emotion | Pain | Opportunity |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Trigger** | Sees a tweet linking to a sketchy seller phone number. Opens ScamReport. | n/a | Determined | Discoverability — Tee learns about ScamReport from a single tweet. | Lightweight web landing page with the same Check box. |
| 2 | **Sign in** | First launch → onboarding → Sign in / Register. He registers with email + password. | Auth flow (`features/auth/`) — Firebase Auth + `POST /auth/sync` to upsert Postgres row. Role defaults to `user` (`require_role.ts:41`). | Mildly impatient | If `POST /auth/sync` is slow, `AuthProvider.ready` stays false and the role gate flashes. `apps/web/CLAUDE.md` §"Auth flow" describes the same logic for the web side. | Show a skeleton, not a redirect, while sync resolves. |
| 3 | **Search** | Taps **Search** → enters seller phone. | Search screen (`features/search/`) → `GET /reports?q=…` (public). Returns 0 hits — first time the number is seen. | Slight letdown | Empty state can read as "this is safe." Misleading. `verdict_pill.dart` uses `unknown` colour for that exact reason. | Show explicit "not enough community evidence yet" CTA → "Submit a precautionary check report." |
| 4 | **Check the seller** | From the empty result, runs **Check** on the same number. AI scores as `suspicious` due to RAG hits in surrounding tags. | `POST /check` (Ask-AI pipeline) | Vindicated | If Gemini is rate-limited the check stays in `pending` for >2s. Crashlytics captures via `crashReporterProvider`. | Inline progress + Gemini fallback to a cached rule-based scoring. |
| 5 | **Submit own report** | Logs his old scam — submits a textual report + screenshot evidence. | `POST /reports` (auth-gated, `reports.route.ts:169`) → file upload via `apps/api/src/core/supabase/storage.ts::uploadFile` | Engaged | Upload caps: ≤5 files, ≤5 MB each, mime allowlist — enforced server-side (`security-reviewer.md` §4). A 12 MB screenshot rejects with no helpful message. | Compress >5 MB images client-side before upload. |
| 6 | **My reports** | Opens **My Reports** → sees his draft pending review. Status pill says `pending`. | Firestore mirror at `/my-reports/{uid}/items/{reportId}` (read-only, owner-only — `firestore.rules:33`) | Patient | Status flips to `pending` even for `flagged` reports — privacy invariant (`firestore_sync.ts::mirrorMyReport`). He never sees flagged. | n/a — invariant is intentional. |
| 7 | **Verified** | Push notification: report verified. Tees feeds shows his number publicly. | FCM topic for the reporter + admin approve in `admin-reports.route.ts:164` → `mirrorMyReport` | Validated | Push delivery flake on stale FCM tokens. | Periodic token refresh + dedupe via `users.fcm_devices`. |
| 8 | **Habit loop** | Returns once a week to check new sellers. Eventually adds 4 reports. | Repeat steps 3–7. | Engaged | Long-tail retention. | Weekly digest push of new "verified" reports tagged for sellers he's checked. |

---

## P3 — Khun Wirat · "Triage 50–100 reports a day"

**Frame:** Khun Wirat is on the partner NGO's moderation rota. He works from a desktop, opens the web admin portal, and aims to clear the queue before lunch.

| # | Stage | Action | Touchpoint | Emotion | Pain | Opportunity |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Sign in** | Goes to the admin URL, signs in with Firebase Web SDK. | `apps/web/src/features/auth/` + `POST /auth/sync`. `<ProtectedRoute role="admin">` reads `user.role` from the synced row. | Routine | A user-role account hitting the admin URL gets a 403 from `requireRole('admin')` (`require_role.ts:79`). Documented in `docs/security/rbac-matrix.md`. | n/a — gating is correct. |
| 2 | **Queue land** | Lands on `/moderation` — sees 73 reports pending. Sorted by oldest first. | `GET /admin/reports` queue list (admin-only). | Focused | If the API CSRF token has expired, all rows fail to fetch. Mitigated by `apiFetch` auto-refresh of Firebase ID token. | Show a stale-token banner if refresh fails. |
| 3 | **Open one** | Clicks a report. Sees full payload — but **no reporter identity** (anonymisation enforced server-side per `SECURITY.md` "In-scope vulnerabilities"). | Admin report detail. Evidence files signed via `getSignedUrl` (expiry 1h). | Confident | Signed URL leaked in a screenshot would expose the file. Mitigated by short expiry + `mappings.txt` not in public web bundle. | Add a watermark in PDF exports. |
| 4 | **Decide** | Approves the report (legit + verifiable). | `POST /admin/reports/:id/approve` → handler calls `mirrorAlert` + `mirrorMyReport` inline (`firestore_sync.ts`). | Decisive | If mirror call fails, action succeeds in Postgres but Firestore lags. Logged + Crashlytics captures; never returned as 500 (`architecture.md` §"Firestore mirror"). Nightly reconciler re-mirrors. | Surface a "mirror lag" indicator if last reconcile > 1h ago. |
| 5 | **Flag** | Spots an outlier — likely retaliation against a small business. Flags instead of rejecting. | `POST /admin/reports/:id/flag` | Cautious | Reporter's `/my-reports/{uid}/items/{reportId}` view shows `pending` even when actually `flagged` (FR-6.1, `firestore_sync.ts`). | Surface "under review" copy in the reporter's app so they're not in the dark. |
| 6 | **Announce** | Drafts a public announcement: "uptick in tax-refund SMS scams this week." | `POST /admin/announcements/:id/publish` → `mirrorAlert` → public read on Firestore + FCM topic. | Civic-minded | Push fan-out is asynchronous; large topics can lag. | Status indicator on the publish dialog so Khun Wirat knows fan-out is in progress. |
| 7 | **Wrap** | Clears queue to <10. Closes laptop. | Returns to dashboard for the daily count. | Done | If he stays signed in on a public terminal, sessions persist. | Aggressive auto-sign-out on idle (rubric-level concern, not coded yet). |

---

## Cross-cutting findings

1. **Locale-switching is invisible.** All three personas implicitly assume Thai. Build switching is tucked into Settings; a one-tap toggle on Home reduces support load.
2. **Empty states are the highest-impact UX surface.** P2's "zero hits = safe" misread is the canonical case — `verdict.unknown` palette exists exactly to undo it, but only verdict screens use it. Apply the same tone to Search empty.
3. **Cross-screen status surfacing.** P3's "flagged" mirror-collapse hides moderator intent from the reporter. Privacy-preserving copy ("under review") would close the loop without compromising the FR-6.1 invariant.
4. **Push permission timing.** Requesting at app start (`initializeFirebase`) is the simplest path, but `apps/mobile/CLAUDE.md` explicitly notes this can be deferred — opportunity to lift FCM opt-in rate.
5. **Web admin is read-heavy + signed-URL-heavy.** Most moderator time is spent reading evidence, not clicking. A keyboard-driven approve/reject flow with `j`/`k` navigation would beat the current click-through cadence.

---

## Source artefacts

- Personas: `docs/presentation.md` §"Slide 5 — Target Users & Personas".
- Screen evidence: `docs/design/screens/*.md` (18 specs) + `docs/design/screenshots/{admin,guest,user}/` (60 PNGs).
- Backing system docs: `docs/architecture.md`, `docs/security/rbac-matrix.md`, `firestore.rules`, `SECURITY.md`.
- Rollback safety net: `docs/rollback-plan.md`, `docs/evidence/rollback-drill.md`.
