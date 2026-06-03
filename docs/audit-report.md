# ScamReport — Enterprise Audit & Orchestration Report

> CSC234 Term Submission · D2 deliverable
> Generated: 2026-05-28 · Branch: `feat/class-submission-deliverables`
> Repo: <https://github.com/CSC234-UserCenteredMobileApp/ScamReport>

## §1 Executive summary

ScamReport is a Flutter + Elysia.js application that lets Thai citizens report and verify suspected scams, and lets a moderator team triage, publish, and broadcast advisories. The codebase is a single Bun workspace monorepo with four parts:

- **`apps/mobile`** — Flutter 3.27 app for Android and Flutter Web, 17 features, Riverpod 2 state, `go_router` routing, Firebase Auth + FCM + Crashlytics + Remote Config + Firestore mirror.
- **`apps/api`** — Elysia.js (Bun) backend, Prisma + Postgres system of record, Supabase Storage for files, Gemini for the Ask-AI conversation surface and embeddings.
- **`apps/web`** — Vite + React + Tailwind + shadcn/ui admin portal hosted on Vercel.
- **`packages/shared`** — TypeBox schemas — the single contract layer. Imported as-is by the API (native Elysia validators), as TS types by the web admin, and codegen'd to Dart for the mobile app.

The project was built using a four-agent Claude Code workflow (Engineer / Architect / QA / Security Reviewer) with strict writer-≠-approver enforcement. This report is the rubric-required D2 audit: agent orchestration in §2, architecture and data in §3, RBAC and Firestore security in §4, observability and rollback in §5, submission checklist in §6.

## §2 Agent workflow

### The four agents

The team uses four named Claude Code agents, each with its own `.md` file under `.claude/agents/` and a hard rule forbidding self-approval. The role split satisfies the rubric requirement that the agent that **writes** a change must not be the agent that **approves** it:

| Agent | File | Role | Writes to |
| --- | --- | --- | --- |
| `engineer` | `.claude/agents/engineer.md` | Implements features per spec. | All source + test files |
| `architect` | `.claude/agents/architect.md` | Reviews diffs against Clean-Arch / schema / design rules. | Review docs only |
| `qa` | `.claude/agents/qa.md` | Authors tests, runs coverage + a11y + perf gates. | Test files + quality docs only |
| `security-reviewer` | `.claude/agents/security-reviewer.md` | Audits security-touching PRs. | Security review docs only |

Each agent's prompt starts with its allowed tool set. The architect's frontmatter is:

```yaml
name: architect
description: Architecture + code review specialist…
tools: Read, Grep, Glob, Bash, WebFetch, TodoWrite, NotebookRead
```

— note the absence of `Write` and `Edit`. The harness will refuse a write call from this session ID, so even if the model attempted to silently fix a problem during review, the tool call would fail. The security reviewer has the same constraint. The engineer and QA agents have `Write`/`Edit`, but QA is restricted by an in-prompt allow-list (`apps/mobile/test/**`, `apps/api/test/**`, two named docs). Any path outside that list is forbidden in the prompt's "Hard rules" section.

### Per-feature loop

The end-to-end loop, from `docs/ai-workflow.md`:

```
Plan Mode (orchestrator)
   ↓ approved plan in ~/.claude/plans/<task>.md
engineer  → branch + PR
   ↓ PR opened (writer agent stops)
architect (different session) → audits Clean-Arch + schema
   ↓ if approved
qa (different session) → extends tests, runs coverage + a11y gates
   ↓ if pass
security-reviewer (different session, only on security-touching PRs)
   ↓ if pass
human reviewer signs off → merge
```

### Handoff protocol

The mechanical floor on writer-≠-approver enforcement is the PR description. Every merged PR ends its body with a trail of agent session IDs:

```
Author agent: engineer · session <id>
Architect agent: architect · session <id>
QA agent: qa · session <id>
Security agent: security-reviewer · session <id> (or n/a)
Human approver: <name>
```

A PR where the same session ID appears twice is auto-rejected by the human reviewer (`docs/ai-workflow.md` §"Writer ≠ approver"). The session IDs are stable filenames inside `~/.claude/projects/<project>/<session>.jsonl` — each one captures the full agent transcript, so the audit trail is durable beyond the conversation window. We attach sanitised excerpts of these transcripts under `docs/evidence/plan-mode/` for the submission package; one such excerpt is `docs/evidence/plan-mode-transcript.md` for this very report.

CI is the second gate. `.github/workflows/ci.yml` runs three matrix jobs (api, mobile, shared), each with a coverage threshold of 80% (90% for `packages/shared`). `.github/workflows/security.yml` runs gitleaks + `bun audit` + `dart analyze --fatal-infos`. A PR that drops coverage, fails secret scan, or introduces a high-severity dependency advisory is blocked at the GitHub checks layer — neither the engineer nor a human can merge until it's green.

### Context-drift handling

The team treats context drift as a first-class risk and mitigates it three ways:

1. **Plan Mode is the entry point.** Every non-trivial change (>3 files or any new feature) starts with Plan Mode. The plan is written to `~/.claude/plans/<task>.md` and approved by a human before the engineer session begins. If scope drifts mid-implementation the engineer is required to **stop and edit the plan file**, then restart from review (`docs/ai-workflow.md` §"Plan-Mode discipline"). The engineer's prompt enforces this: "If anything is ambiguous, ask **before** writing code, not after."
2. **Required reading before writing code.** The engineer prompt lists six documents that must be read in full per task: the plan, `docs/architecture.md`, `docs/design-review.md`, the relevant `docs/design/screens/<screen>.md`, `docs/design/components.md`, and the per-app `CLAUDE.md`. This pulls the design language and Clean-Arch rules into the agent's working context, so its first edit is grounded in project conventions rather than in pre-training generality.
3. **A new session per role.** Because each role is a new Claude Code session, the architect doesn't inherit the engineer's narrative bias toward "this is fine, ship it." The architect re-reads the diff cold against the rule set in its prompt. The same is true for the QA and security passes. If the engineer pushed back on a rule mid-PR ("but in this case it's safe to import from data/"), that rationalisation never leaves the engineer's transcript — the architect never sees it.

If any reviewer hits a boundary case the prompt doesn't cover (a new SDK, a new auth path, a schema migration without a clear precedent), the rule is to **block and escalate to the human Architect (P2)**: "False approvals cost more than false blocks" (`.claude/agents/architect.md` §"Hard rules"). The human owner of that area is accountable on rubric day, so an unsure agent yielding to them is the correct behaviour.

## §3 Architecture & data

### Monorepo layout

```
ScamReport/
├── apps/
│   ├── mobile/   Flutter — Android + Web
│   ├── api/      Elysia.js + Prisma + Postgres
│   └── web/      Vite + React (admin)
├── packages/
│   └── shared/   TypeBox schemas (single contract layer)
└── docs/         architecture, design, ADRs, evidence
```

The four pieces talk to each other through `packages/shared`. Every TypeBox schema is JSON Schema, so the API uses them natively as Elysia validators, the web admin imports them as `Static<>` TypeScript types, and the mobile app gets Dart equivalents via `scripts/codegen.sh`. No DTO is handwritten on the mobile side — schema drift surfaces at compile time or at the response validator (`apiFetch` in the web admin runs `TypeCompiler.Compile(...).Check(...)` on every payload).

### Mobile Clean Architecture

The Flutter app is feature-first: everything for a feature lives in `lib/features/<feature>/{data,domain,presentation}`. Cross-cutting wiring (theme, router, DI, cache, feature flags, observability) lives in `lib/core/`. The layer rules, from `docs/architecture.md`:

| Layer | Allowed deps | Owns |
| --- | --- | --- |
| `presentation/` | `domain/` + `core/` + Flutter + Riverpod | Screens, widgets, Riverpod providers |
| `domain/` | nothing project-specific (pure Dart) | Entities, use-cases, `Result<T, Failure>`, **repository interfaces** |
| `data/` | implements `domain/` interfaces + DTOs from `core/api_types/` + Firestore SDK / HTTP | Repository implementations + DTO mappers |

The arrow direction is the rule: `presentation → domain ← data`. The architect agent blocks any PR that crosses it the wrong way (a screen importing a repository, a domain entity importing a Firestore type). The mechanical check is in `.claude/agents/architect.md` §1 — "A widget calling a repository directly = **block the merge**."

### State management — why Riverpod, not BLoC

The mobile CLAUDE.md states the choice in one line: *"State: Riverpod 2 — compile-safe DI, testable without `BuildContext`."* Three concrete properties drove that decision:

1. **Compile-safe DI.** A Riverpod `Provider<T>` is a typed singleton. A widget that asks for the wrong type gets a build error, not a runtime missing-dependency cast. BLoC's `BlocProvider.of<MyBloc>(context)` is a runtime lookup — wrong type or missing provider blows up at scroll time.
2. **Override-based testing.** Every Riverpod test pumps a `ProviderScope(overrides: [repo.overrideWithValue(_FakeRepo())], child: …)`. The fake is wired in at one place and survives the whole widget tree. BLoC tests typically need `BlocProvider.value(value: _FakeBloc(), child: …)` repeated per screen, or a custom mock factory. The architect agent's review template uses Riverpod overrides as the canonical test recipe in `.claude/agents/qa.md`.
3. **`family` providers for per-key dependencies.** Several features need "the repo for argument X" — e.g. the verdict screen reads a specific report by ID. `Provider.family<Report, String>` expresses that directly. The same shape in BLoC is two-tier (`BlocProvider` + `Bloc` keyed by ID), which doubles the boilerplate for a feature-first app with 17 features.

The trade-off accepted: Riverpod 2's auto-dispose + family combinatorics has a steeper learning curve than BLoC's event-stream mental model. The team mitigates by enforcing `presentation/` thinness — a widget either reads a value from a provider or dispatches a user action; everything else lives in the use-case in `domain/`.

### Firestore mirror — narrow polyglot persistence

Postgres is the system of record. Firestore mirrors **only two read surfaces** to satisfy the rubric's "polyglot persistence + offline-first" requirement without cross-store consistency headaches:

```
firestore/
├── alerts/{announcementId}                 ← mirror of announcements (public)
└── my-reports/{uid}/items/{reportId}       ← mirror of reports (owner-only)
```

The mirror is sync-only: the API writes Postgres, then calls `apps/api/src/sync/firestore_sync.ts::mirrorAlert(...)` or `mirrorMyReport(...)` inline at the end of the route handler, using the Firebase Admin SDK (which bypasses Firestore rules). **Mirror failure is logged + captured by Crashlytics, never returned as a 500** — the Postgres write succeeded, so user-visible state is correct; a nightly reconciliation job re-mirrors divergences (`docs/architecture.md` §"Firestore mirror").

The mirror writer also collapses the `flagged` status to `pending` for the reporter's view (PRD FR-6.1) so the user is never tipped off about an ongoing moderation review. This is a privacy invariant enforced server-side, not a client-side filter.

### Contract-first workflow

Every endpoint starts with a schema in `packages/shared`:

```
1. Edit / add schema in packages/shared/src/schemas/<area>.ts
2. Re-export from packages/shared/src/index.ts
3. Import in apps/api/src/features/<name>/<name>.route.ts (body / response)
4. Run ./scripts/codegen.sh → apps/mobile/lib/core/api_types/*.dart regenerates
5. Consume the Dart types in apps/mobile/lib/features/<feature>/data/
```

If a server schema changes without the codegen step, the mobile build breaks the same day. There is no third source of truth, so there is no opportunity to drift.

## §4 Security matrix

The full RBAC + Firestore rules tables live in `docs/security/rbac-matrix.md`. This section summarises the policy.

### Three roles, server-side resolution

`guest` (no token), `user`, `admin`. The role is resolved on the **server**, not from a Firebase custom claim:

```ts
// apps/api/src/core/middleware/require_role.ts:25
async function verifyBearerWithRole(authHeader) {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const decoded = await getAuth(getFirebaseAdmin()).verifyIdToken(token);
  const row = await getPrisma().user.findUnique({
    where: { firebaseUid: decoded.uid }, select: { role: true },
  });
  const role: Role = row?.role === 'admin' ? 'admin' : 'user';
  return { uid: decoded.uid, email: decoded.email ?? null, role };
}
```

The comment in the file explains the choice: *"Firebase custom claims are intentionally NOT used — admin promotion is a single SQL update, with no token-refresh dance and no dual-write surface."* The Postgres `users.role` enum (`user` / `admin`) is the canonical source. The web admin portal makes the same choice — its `<ProtectedRoute role="admin">` reads from `POST /auth/sync` (which returns the Postgres row), never from a token claim.

### Endpoint surface

There are **47** routes across 13 feature directories under `apps/api/src/features/`. Of those:

- **8 are public** (health, stats, scam-types, announcements list/detail, check / check recent, public reports list / detail).
- **15 require an authenticated user** (`/auth/sync`, `/reports/*` mutations, `/ask-ai/*`, `/me/notifications/*`).
- **24 require admin** (every `/admin/*` route — moderation queue, announcements, scammers, persons, AI-eval dashboards, scam overview, exports, platform summary, notifications jobs).

Every admin route is the result of `.use(requireRole('admin'))` at the route-group level. A guest gets a 401, an authenticated regular user gets a 403. Owner-scoped routes (PATCH a draft, DELETE your own report) additionally check `report.reporterId === user.uid` at handler level and return 404 (not 403) on mismatch to avoid existence enumeration. The full endpoint × role table is in `docs/security/rbac-matrix.md`.

### Reporter anonymisation

Admin endpoints **never** serialise reporter identity. The serializer for every `/admin/reports*` payload drops `reporter_user_id`, `email`, `display_name`, `handle`, and `avatar_url` before the response leaves the server. This is verified by `apps/api/test/admin-reports.test.ts`. The rule is documented in `SECURITY.md` "In-scope vulnerabilities" and codified in PRD §FR-7.4 / FR-7.8.

### Firestore rules

`firestore.rules` is 43 lines, including comments:

```js
service cloud.firestore {
  match /databases/{database}/documents {
    match /alerts/{announcementId} {
      allow read: if true;        // public announcements
      allow write: if false;      // server-only via Admin SDK
    }
    match /my-reports/{uid}/items/{reportId} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow write: if false;      // submission goes through API
    }
    match /{document=**} {        // default deny
      allow read, write: if false;
    }
  }
}
```

The default-deny is defence-in-depth: a future PR that adds a new collection without adding a rule for it will fail closed. The owner-equality check (`request.auth.uid == uid`) leans on the path itself to encode ownership — there is no document-level metadata for a client to spoof.

### Threat model

The security-reviewer agent's prompt enumerates the surfaces and the concern per surface (`.claude/agents/security-reviewer.md`):

| Surface | Concern |
| --- | --- |
| Auth (Firebase) | session hijack, token leakage, broken biometric fallback |
| RBAC | guest/user reaching admin-only routes; admin acting on someone else's draft |
| User-submitted reports | XSS / injection in stored content; unbounded uploads; PII in audit logs |
| Firestore | over-permissive rules; client mutating admin-owned collections |
| Postgres / Prisma | raw queries with interpolation; N+1 leaking IDs; missing tenant filter |
| Secrets | service-account JSON, Firebase API keys, signing keystore checked in |
| FCM push | unauthenticated send; user enumeration via topic names |
| Static assets | bundled `.env`, `mappings.txt`, debug builds shipped |

Each PR that touches a row in this table triggers the security-reviewer agent, which runs nine concrete checks before voting (`security-reviewer.md` §"Checks for every PR"): secret scan, `.env`/config hygiene, auth surface coverage, input validation, Prisma usage (no `$queryRaw` with template interpolation, `take` clamps), Firestore rules diff review, logging hygiene (no PII in `console.log`), `bun audit`, CI signing surface. A `High` finding always blocks; `Medium` requires explicit architect acceptance noted in the audit report.

### Standing controls (CI-enforced, every PR)

| Control | Where | Verified by |
| --- | --- | --- |
| Secret scan | `gitleaks detect` in `.github/workflows/security.yml` | CI + security-reviewer agent |
| Dependency audit | `bun audit` (high/critical fails CI) | CI |
| Static analysis | `dart analyze --fatal-infos`, `bun run typecheck` | CI |
| Auth gate on mutating routes | `requireAuth()` / `requireRole(...)` middleware | architect + security-reviewer |
| Reporter anonymisation | response-shape tests | security-reviewer |
| Firestore rules | manual diff review on `firestore.rules` changes | security-reviewer |
| `.env` hygiene | `.env*` gitignored, only `.env.example` tracked | security-reviewer |

(`SECURITY.md` §"Internal controls".) The CI pipeline runs all of the above on every PR; nothing reaches `main` without passing.

## §5 Observability & rollback

### Crashlytics wiring

`apps/mobile/lib/core/di/firebase.dart::initializeFirebase()` is called from `main.dart` before `runApp`. It does four things in order:

1. `Firebase.initializeApp(...)` — typed options from `firebase_options.dart` (a `flutterfire configure` output, gitignored; the `.example` template is tracked).
2. `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode)` — collection is disabled in debug so dev crashes don't pollute the prod dashboard; release builds collect from the first frame.
3. `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, ...)` — offline persistence is on by default for both the announcement mirror and the per-user reports mirror.
4. `FirebaseRemoteConfig.instance` is initialised with **defaults of `false`** for every feature flag (`enable_biometric_login`, `enable_clipboard_scanner`, `enable_share_target`, `enable_ai_search`, `enable_ask_ai`, `enable_call_screening`, `enable_sms_scan`). A failed fetch therefore never silently turns a feature on; flag promotion is an explicit action in the Firebase Console.

`FlutterError.onError` and the platform-error handler are wired in `main.dart` to `FirebaseCrashlytics.instance.recordFlutterFatalError` and `.recordError(... fatal: true)` respectively, so every uncaught exception in either zone reaches the dashboard.

### Crashlytics tagging — what we attach to every report

The team uses `CrashReporter` (`apps/mobile/lib/core/observability/crash_reporter.dart`) as the entry point for everything except the framework-level fatal handler. Three categories of context get attached to each crash report:

- **`setUserId(uid)`** — called from the auth provider once `users.role` is known. Mirrors the Crashlytics dashboard's "User ID" pivot so a stack trace can be grouped by user without exposing email or handle.
- **`setKey(key, value)`** — used for feature-flag state and the offline-status snapshot. Examples currently set in the wild: `enable_ask_ai`, `enable_sms_scan`, `last_sync_seconds_ago`, `cache_hit_rate`. These show up in the Crashlytics dashboard as filterable custom keys so a per-flag spike can be isolated.
- **`log(message)`** — short breadcrumbs at major lifecycle transitions (login, screen mount, mutation start, sync complete). The dashboard shows the last few breadcrumbs above every stack trace, which is usually enough to reproduce a flaky path.

Non-fatal exceptions caught at the data layer call `CrashReporter.recordNonFatal(error, stack, reason: ..., information: [...])`, which falls back to `developer.log` in debug. The fallback path is the reason no test will accidentally page Crashlytics in CI.

Acceptance target from PRD §6.8: **crash-free user rate ≥ 99% per release**, **every crash session reproducible from the dashboard within 24h**.

### Rollback procedures

`docs/rollback-plan.md` lists four. Triggered when any of: crash-free rate drops below 99% within an hour, ≥2 user reports of a broken feature in 24h, a High finding from the security workflow lands on already-merged code, or a migration corrupts data.

**Procedure 1 — feature flag flip (preferred).** Every S2+ feature is wrapped in `FeatureFlags.isEnabled('feature_key')` reading from Remote Config (`apps/mobile/lib/core/feature_flags/feature_flags.dart`). To disable: open Firebase Console → Remote Config, find the flag, set production to `false`, save + publish. Mobile clients pick it up on the next `fetchAndActivate()` (cold start or scheduled refresh). **No app redeploy required.** This is the rubric-aligned mechanism; A.P runs one dry-run before the final demo on a staging Remote Config template, with the timeline captured in `docs/evidence/rollback-drill.md`.

**Procedure 2 — revert merge commit.** For non-flag-gated work or when the flag itself is broken: `git revert -m 1 <merge-sha>` on a fresh `main`, open a hotfix PR titled `chore(revert): …`, skip the architect/qa loop only if the diff is purely a revert. Merge after CI green. If the affected feature is still callable from the client, additionally flip its flag (Procedure 1).

**Procedure 3 — Prisma migration revert.** Prisma has no automatic down-migration: the team writes a **new** down-style migration, lands it via PR, applies it with `bun --filter @my-product/api prisma migrate deploy`. Never edit applied migrations in place — that breaks every other developer's local state.

**Procedure 4 — Firestore rules revert.** `firebase deploy --only firestore:rules` from the previous green commit's `firestore.rules`. If the bug is in the mirror writer rather than the rules, follow Procedure 2 and (optionally) flip the affected client read flag with Procedure 1.

### Test coverage and observability evidence

Mobile coverage is 81.04% (`docs/test-report.md`), API is above the 80% gate, shared is above the 90% gate. CI fails closed below those thresholds. The full evidence trail lives under `docs/evidence/`:

- `docs/evidence/plan-mode-transcript.md` — narrative of the planning session that produced this very report.
- `docs/evidence/ci-runs/` — links to the green CI run per merged PR.
- `docs/evidence/coverage/` — lcov per release tag.
- `docs/evidence/rollback-drill.md` — the Procedure-1 dry-run timeline.
- Golden tests for two stable widget surfaces are committed under `apps/mobile/test/widgets/goldens/`; the test sources are at `apps/mobile/test/widgets/*_golden_test.dart` and run on every CI pass.

## §6 Submission checklist

| Deliverable | Path / URL | Status |
| --- | --- | --- |
| **D1 — Git repository** | https://github.com/CSC234-UserCenteredMobileApp/ScamReport | ✓ |
| Complete Flutter source | `apps/mobile/` (17 features) | ✓ |
| Root + per-app `CLAUDE.md` (×5) | `CLAUDE.md`, `apps/{mobile,api,web}/CLAUDE.md`, `packages/shared/CLAUDE.md` | ✓ |
| Agent definitions | `.claude/agents/{architect,engineer,qa,security-reviewer}.md` | ✓ |
| CI — format / analyze / test | `.github/workflows/ci.yml` (api, mobile, shared) + `security.yml` (gitleaks, bun-audit, dart-analyze) | ✓ |
| Zero secrets in history | `.gitleaks.toml` + secret-scan workflow; service-account file is `.gitignore`d and never tracked | ✓ |
| **D2 — Audit report** | `docs/audit-report.md` (this file) | ✓ |
| RBAC matrix + Firestore breakdown | `docs/security/rbac-matrix.md` | ✓ |
| Agent workflow | `docs/ai-workflow.md` | ✓ |
| Architecture | `docs/architecture.md` | ✓ |
| Rollback plan | `docs/rollback-plan.md` | ✓ |
| **D4 — Evidence package** | `docs/evidence/` | partial |
| Plan-Mode agent transcript | `docs/evidence/plan-mode-transcript.md` | ✓ |
| Golden tests | `apps/mobile/test/widgets/*_golden_test.dart` + `goldens/*.png` | ✓ |
| Design artefacts (per-screen specs) | `docs/design/screens/*.md` (18 files) | ✓ |
| Per-role design snapshots (admin / guest / user) | `docs/design/snapshots/` (180 files) | ✓ |
| Per-role design screenshots | `docs/design/screenshots/{admin,guest,user}/` | ✓ |
| User personas | `docs/presentation.md` §2 (Aunty Som, Tee, Khun Wirat) | ✓ |
| Test report | `docs/test-report.md` (coverage by app + feature) | ✓ |
| Rollback drill evidence | `docs/evidence/rollback-drill.md` | user task |
| Crashlytics dashboard screenshots | `docs/evidence/crashlytics/` | user task |
| Android + Web runtime screenshots | `docs/evidence/runtime/` | user task |
| WBS / Gantt / UJM | `docs/pm/` | user task |

The "user task" rows are deliverables that require live captures (production dashboards, device screenshots, course-specific project management artefacts) and are owned by the team rather than generated from the code. Everything in the codebase column is committed in this branch.

---

# Addendum — 2026-06-03 rubric-closure pass

A final audit against the term-assignment rubric drove one feature + seven
compliance work-packages (branch `feat/app-lock-biometric-pin`). Summary for
graders; details in the named docs/tests.

## New since 2026-05-29

| Item | Evidence |
| --- | --- |
| Biometric app-lock + 6-digit PIN fallback (R1) | `apps/mobile/lib/features/app_lock/` — Keystore-backed PIN (PBKDF2-HMAC-SHA256, vector-tested), persisted lockout w/ backoff, fail-closed overlay gate, `FlutterFragmentActivity`; 66 feature tests |
| Firestore rules demonstration (R1/C) | `firestore.rules` `profiles/{uid}`: owner isolation, **`diff().affectedKeys()`** whitelist on update, field-level type/size checks, **`request.time == updatedAt`** server-timestamp validation. 12-case emulator suite `apps/api/test/firestore-rules/` + `security.yml` CI job. Mobile edit-profile slice writes it |
| Clean-Architecture guard (R2) | `settings` domain purified (`AppThemeMode`); `test/arch/domain_purity_test.dart` fails any future Flutter/Firebase/Riverpod import under `domain/` |
| Riverpod code generation (R2) | `home`, `platform_summary`, `profile` use `@riverpod` (riverpod_generator). **Justification for hybrid:** the remaining hand-written providers predate codegen, are equally type-safe under Riverpod 2, and a wholesale migration would churn ~19 files + every test override for zero behavioural gain; codegen is demonstrated on three representative shapes (function provider, FutureProvider, class notifier) and is the default for new features |
| A11y quality gate (R5) | `test/a11y/a11y_sweep_test.dart` — contrast / tap-target / labeled-tap guidelines + textScale-2.0 across 5 core screens. Fixes: light-theme primary `#C8481B` (white-on-primary 4.77:1; coral text 4.57:1 — original `#F25F2A` failed at 3.26/3.12), 48 dp targets, labeled back button, dynamic-type-safe rows. `docs/accessibility-checklist.md` |
| Performance (R5) | All 9 `Image.network` sites → `CachedNetworkImage`; `image_picker` `imageQuality: 80, maxWidth: 1920`; `docs/performance-budget.md`; bounded `ListView(children:)` audit recorded there |
| Integration tests (R5) | `integration_test/app_flows_test.dart` — 3 flows (home stats, check→verdict, login→settings→sign-out) with faked Firebase/API via Riverpod seams; `integration.yml` CI: Android emulator (API 34) + headless-Chrome `flutter drive`; `flutter build web` added to ci.yml |
| Widget-test backfill | +8 screen suites (44 tests): legal ×2, notifications inbox, my-reports, edit-report, admin announcements ×2, platform summary. The platform-summary suite caught a live `ParentDataWidget` defect (`Expanded` under `SizedBox` in a `Wrap`) — fixed |
| D4 artefacts | `docs/project-plan.md` (WBS + Gantt + PDM), `docs/design/personas.md`, debug-only Crashlytics evidence button in Settings (tap = non-fatal, long-press = fatal) |

## Notes for graders (interpretations + accepted risks)

- **"Web WebAuthn" (R1):** read as *Android Keystore **or** WebAuthn* for the
  biometric fallback. The shipped lock uses Android Keystore + biometrics; on
  Flutter web it degrades to PIN-only (no `local_auth` web implementation).
- **Composite indexes (R4):** `firestore.indexes.json` is intentionally empty —
  Firestore is a 3-collection read surface (2 server-written mirrors + the
  rules-validated profile doc) addressed by path; Postgres is the system of
  record for every compound query. An index added here would be dead config.
- **Secret history:** Firebase *client* keys (not service credentials) were
  committed early in the project; the files are now gitignored with `.example`
  templates and gitleaks gates CI. Recommendation on record: rotate the keys
  before the public showcase. No server-side secrets ever committed.
- **Recents privacy:** app-lock masks the task-switcher thumbnail with a
  best-effort widget cover (product decision: screenshots stay allowed, no
  `FLAG_SECURE`); a snapshot race on some OEMs can briefly show the last frame.
- **Lockout clock:** PIN lockout is wall-clock based; a user who can change the
  system clock gains ~1 extra guess per change against a 10⁶ keyspace stored
  in Keystore-backed storage. Accepted.
