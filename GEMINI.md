# GEMINI.md — ScamReport

This is a mobile product built on Flutter (app) + Elysia.js (backend on Bun) + a shared TypeBox contract package.

## Product Context

The **Scam Report Platform** primarily targets Android (full feature set) with a Flutter Web build that ships only the public surface (verdict, feed, alerts, login, legal). It allows users to quickly verify suspicious phone numbers, URLs, or messages against a community-sourced scam database.
- **Quick Verdicts**: Returns a colour-coded verdict (Scam, Suspicious, Safe, Unknown) within 3 seconds.
- **AI Semantic Search**: Provides natural-language search over scam reports using RAG (Gemini + `pgvector`).
- **Proactive Interception**: Share-sheet and clipboard scanning features on Android.

### Direction (v1.2, 2026-04-28)
- **Platforms**: Android primary (full feature set). Flutter Web public-surface only — no biometric, no submit, no admin on Web. No iOS.
- **Reporter Statuses**: Strictly `Pending`, `Verified`, `Rejected`. An admin status of `flagged` maps to `Pending` in all reporter-facing views.
- **Reporter Anonymity**: Admin views and audit logs **never** display reporter identity. API strips reporter fields from `/admin/*` and `/mod/*` responses.
- **Push Notifications**: Automatic FCM notifications for two cases: report status change (to reporter) and new announcements (to all). No topic subscriptions or user toggles.
- **Firestore (narrow scope)**: `alerts` + `my-reports/{uid}/items` mirror only — read-only on the client, server-only writes via admin SDK. Postgres is system of record.
- **Biometric**: Android `local_auth` fallback for re-unlock; not on Web.
- **Feature flags**: Firebase Remote Config; new features default-off in prod.
- **Coverage target**: ≥ 80% line coverage all packages; CI gate enforces.
- **Official Scam Types**: `phone_impersonation`, `phishing_sms`, `fake_qr`, `ecommerce_fraud`, `investment`, `romance`.

## Architecture

The project follows a monorepo structure with three main areas:
- **`apps/mobile`**: Flutter app. Feature-first layout (`lib/features/<feature>/{data,domain,presentation}`). Uses Riverpod for state and `drift` for local SQLite caching.
- **`apps/api`**: Elysia.js + Prisma v7 backend. Feature-first layout (`src/features/<feature>/`).
- **`packages/shared`**: TypeBox schemas shared between api and mobile.

**Core Infrastructure:**
- **Data Layer**: PostgreSQL on **Supabase** (Postgres 15) utilizing **`pgvector`** for semantic similarity search.
- **Auth & Push**: **Firebase Authentication** (Google OAuth/Email) and **Firebase Cloud Messaging (FCM)**.
- **AI/LLM**: **Gemini API** (`text-embedding-004`) for generating embeddings of scam reports.

## Multi-agent Workflow

The project uses a strict multi-agent workflow to meet the `CSC234` term-assignment rubric. The core rule is **Writer != Approver**.
- **`engineer`**: Implements features, writes code and tests, and opens PRs.
- **`architect`**: Runs in a separate session to review PRs against Clean Architecture and design rules.
- **`qa`**: Runs in a separate session to extend test coverage and verify quality.
- **`security-reviewer`**: Audits PRs touching auth, secrets, or database rules.

Every implementation **MUST** start with a human-approved plan in `~/.claude/plans/`. An agent that writes code **MUST NOT** approve its own work.

## Design Specs

The design prototype is distilled into markdown specifications in `docs/design/`.
- **Theming**: Rely strictly on the `VerdictPalette` extension and `ColorScheme` tokens in `app_theme.dart`. **No hardcoded hex values.**
- **Components**: Prioritize using widgets from `docs/design/components.md` before inventing new ones.
- **Screens**: Each screen has a layout and interaction spec in `docs/design/screens/<name>.md`.

## Key Documentation

Always refer to these files for detailed rules and specs:
- **`PRODUCT-REQUIREMENTS.md`**: Authoritative source for product flows and functional requirements.
- **`DATABASE_DESIGN.md`**: Detailed schema definitions and enumerated types.
- **`docs/architecture.md`**: High-level system design and Clean-Arch rules.
- **`docs/ai-workflow.md`**: Detailed multi-agent orchestration and accountability rules.
- **`docs/design/index.md`**: Entry point for screen and component specifications.
- **`.claude/agents/`**: Configuration and hard rules for specialized agents.
- **`HOW_TO_CONTRIBUTE.md`**: Development setup and branch conventions.

## Contract-first Workflow

Every endpoint starts with a schema in `packages/shared`.
1. Edit/add schema in `packages/shared/src/schemas/<area>.ts`.
2. Re-export from `packages/shared/src/index.ts`.
3. Import in `apps/api/src/features/<name>/<name>.route.ts` and use as a validator.
4. **CRITICAL:** Run `./scripts/codegen.sh` from the repo root to regenerate Dart types into `apps/mobile/lib/core/api_types/`.
5. Consume the Dart types in `apps/mobile/lib/features/<feature>/data/`.

## Common Tasks

### Adding a new API endpoint
1. Define the contract in `packages/shared/src/schemas/`. Re-export from `index.ts`.
2. Create the route plugin at `apps/api/src/features/<feature>/<feature>.route.ts`. Use the shared schema.
3. Register the plugin in `apps/api/src/index.ts`.
4. Write a test at `apps/api/test/<name>.test.ts`.
5. Run `./scripts/codegen.sh`.

### Adding a new Flutter feature
1. Create folders under `apps/mobile/lib/features/<feature>/`: `domain/`, `data/`, `presentation/`.
2. Add files: `<feature>_entity.dart` (domain), `<feature>_repository.dart` (data), `<feature>_screen.dart` and `<feature>_providers.dart` (presentation).
3. Wire routing in `apps/mobile/lib/core/router/app_router.dart`.
4. Add tests under `apps/mobile/test/features/<feature>/`.

## Top-level Commands (run from repo root)

| Command | Purpose |
| --- | --- |
| `bun install` | Install all workspace deps |
| `bun run dev` | Run api + mobile concurrently |
| `bun run test` | Run all tests across workspaces |
| `bun run typecheck` | Typecheck shared + api |
| `bun run lint` | Run `dart analyze` on mobile |
| `bun run prisma:generate` | Generate Prisma client |

## Testing Expectations (PR Checklist)

- **api:** `bun --filter @my-product/api test` must pass if api was touched.
- **mobile:** `cd apps/mobile && dart analyze && flutter test` must pass if mobile was touched.
- **Coverage:** `flutter test --coverage` and `bun test --coverage` must hit ≥ 80% line per package; CI fails any drop.
- **Manual:** Manually exercise the affected flow on at least one platform.

## Workspace Specific Rules

When working within a specific app, make sure to read its local `GEMINI.md`:
- `apps/api/GEMINI.md`
- `apps/mobile/GEMINI.md`
- `packages/shared/GEMINI.md`
