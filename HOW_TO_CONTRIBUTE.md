# How to contribute

Welcome. This guide gets you from a fresh clone to a running app and tells you where to add things.

## 1. Prerequisites

| Tool | Version | Install |
| --- | --- | --- |
| Bun | ≥ 1.1 | https://bun.sh |
| Flutter | ≥ 3.27 (stable) | https://docs.flutter.dev/get-started/install |
| PostgreSQL | ≥ 14 (local or hosted) | https://www.postgresql.org/download/ |
| Android Studio | latest | for Android emulator + SDK + signing |
| Firebase CLI | latest | https://firebase.google.com/docs/cli (only needed if touching `firestore.rules`, deploying Hosting, or running emulators) |

## 2. First-run setup

```bash
# 1. Install workspace deps
bun install

# 2. Generate Flutter Android (+ Web) platform folders (one-time, per clone)
cd apps/mobile && flutter create --platforms=android,web . && cd ../..

# 3. Create your .env from the example and fill in DATABASE_URL
cp apps/api/.env.example apps/api/.env

# 4. Place Firebase config files (see "Firebase setup" below)

# 5. Generate the Prisma client
bun run prisma:generate

# 6. (optional) Make scripts executable
chmod +x scripts/*.sh

# 7. Start dev (api + mobile)
bun run dev
```

## 3. External services & secrets

We use three external services. None of their secrets are committed; ask the team lead for current values.

### 3.1 Firebase (mobile + backend)

**Mobile config files** (gitignored — place locally):
- Android: `apps/mobile/android/app/google-services.json`
- Web: configured via `apps/mobile/web/firebase-config.js` per Firebase Hosting setup (see Firebase Console → Project settings → Your apps → Web app → SDK setup and configuration).

Mobile init runs from `apps/mobile/lib/core/di/firebase.dart`. If the config files aren't present, init logs a warning and returns false — the app still boots, just without Firebase features.

**Backend service account** (gitignored — place locally):
- Download from Firebase Console → Project Settings → Service accounts → "Generate new private key".
- Save as `apps/api/firebase-service-account.json` (matches the default `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env.example`).

**Firestore (used in narrow scope — alerts + my-reports mirror, see `docs/architecture.md`):**
1. Firebase Console → Firestore Database → Create database (Production mode, region close to users).
2. Deploy security rules: `firebase deploy --only firestore:rules` from the repo root (uses `firestore.rules`).
3. Confirm the rules in the Firebase Console match the file before any client work begins.

### 3.2 Supabase (backend only — mobile never talks to Supabase directly)

In `apps/api/.env` set:
- `DATABASE_URL` — Supabase pooler URL (port `6543`, `?pgbouncer=true`). Used by Prisma at runtime.
- `DIRECT_URL` — Supabase direct URL (port `5432`). Used by `prisma migrate` only.
- `SUPABASE_URL` — `https://YOUR-PROJECT-REF.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY` — Project Settings → API → `service_role` (server-side ONLY; never ship to mobile).

Create any Storage buckets your features need via the Supabase dashboard (e.g. an `uploads` bucket). Buckets are not provisioned by code.

### 3.3 Gemini (backend only)

Get a key at https://aistudio.google.com/app/apikey and put it in `apps/api/.env` as `GEMINI_API_KEY`. The backend client lives at `apps/api/src/core/gemini/client.ts`.

## 4. Mobile API base URL

The mobile app picks its API base URL from a compile-time env. Default is `http://localhost:3000`, which works on iOS simulators and desktop.

| Target | How to run |
| --- | --- |
| Web browser (public surface only) | `cd apps/mobile && flutter run -d chrome` |
| Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` |
| Physical Android device | `flutter run --dart-define=API_BASE_URL=http://<LAN-ip>:3000` |

> **Platform note:** Android ships the full feature set (verdict, feed, AI search, submit, my-reports, alerts, biometric login, moderation, announcement editor). Web ships only the public surface (verdict, feed, alerts, login, legal). Mobile-only features are gated by `kIsWeb` in `presentation/`. iOS is **out of scope** for this release.

The constant lives at `apps/mobile/lib/core/api_client.dart`. Edit there if you ever need a different default.

## 5. Where to add things

### Adding a new API endpoint

1. Add/extend the TypeBox schema in `packages/shared/src/schemas/<area>.ts` and re-export from `packages/shared/src/index.ts`.
2. Create `apps/api/src/features/<name>/<name>.route.ts` exporting an Elysia plugin. Use the shared schema for `body` / `response`.
3. Mount the plugin in `apps/api/src/index.ts`.
4. Add a test in `apps/api/test/`.
5. Run `./scripts/codegen.sh` so the mobile app gets updated Dart types.

See also: `/add-endpoint` slash command.

### Adding a new Flutter feature

1. Create `apps/mobile/lib/features/<feature>/{data,domain,presentation}/`.
2. `domain/` = entities and use cases (no Flutter imports).
3. `data/` = repositories, API clients (imports from `core/api_types/`).
4. `presentation/` = widgets and Riverpod providers.
5. Wire any required routes in `apps/mobile/lib/core/router/`.
6. Add a test under `apps/mobile/test/features/<feature>/`.

See also: `/add-feature` slash command.

### Persisting data on the mobile app

Three layers — pick the smallest that fits:

| Use case | Tool | Provider |
| --- | --- | --- |
| Theme, "has seen onboarding", small flags | `shared_preferences` | `sharedPreferencesProvider` |
| Refresh tokens, anything sensitive | `flutter_secure_storage` | `secureStorageProvider` |
| Cached API responses, drafts, queryable data | `drift` (SQLite) via `AppDatabase` | `appDatabaseProvider` |

Drift schemas live in `apps/mobile/lib/core/cache/app_database.dart`. After editing tables, re-run `dart run build_runner build --delete-conflicting-outputs` from `apps/mobile/`. The generated `app_database.g.dart` is committed so teammates don't need to run codegen on every clone.

### Changing a shared schema

Anyone touching `packages/shared` must run `./scripts/codegen.sh` before pushing so mobile Dart types stay in sync.

## 6. Branches, commits, PRs

- Branches: `feat/<short-name>`, `fix/<short-name>`, `chore/<short-name>`
- Commits: imperative mood, ~72 chars first line; body explains the *why*
- Open a PR against `main`; CODEOWNERS auto-routes reviewers (see `CODEOWNERS`)
- **Tests must pass before opening the PR** — team rule, 2026-04-28. CI is a backstop, not a substitute for running tests locally first.
- Integration tests across feature boundaries are **S.P's responsibility** — feature authors hand them off after their unit/widget tests pass.
- The PR template (`.github/PULL_REQUEST_TEMPLATE.md`) requires the **agent-trail block** (rubric: writer ≠ approver). Same session ID twice = auto-rejected.

### PR checklist (the template fills this in for you)

- [ ] `bun run typecheck` passes
- [ ] `bun run test` passes
- [ ] `bun run lint` passes (mobile changes)
- [ ] Coverage did not drop below 80% line per package
- [ ] Shared schema changes committed alongside consumer changes in api + mobile
- [ ] No Firebase / env / service-account / keystore files committed
- [ ] Agent-trail block filled in (engineer / architect / qa / security-reviewer / human approver)
- [ ] Docs touched (per W2 sync map in the term-assignment plan) ticked or justified

## 7. Testing expectations

- **api** — every route has at least one test under `apps/api/test/`. Coverage gate: ≥ 80% line.
- **shared** — schemas should round-trip sample payloads; keep tests fast. Coverage gate: ≥ 90%.
- **mobile** — unit-test domain logic; widget-test `presentation/` for every screen; integration-test critical flows under `apps/mobile/integration_test/`. Coverage gate: ≥ 80% line.
- **Integration tests are S.P's domain.** Feature authors write the unit + widget layer; S.P writes the cross-feature integration once those pass. If you need an integration scenario added, ping S.P.

## 8. Multi-agent workflow

The team uses four Claude Code agents — `engineer` / `architect` / `qa` / `security-reviewer` — to satisfy the rubric's writer ≠ approver rule. The full loop, hard rules, and evidence-trail conventions live in [`docs/ai-workflow.md`](./docs/ai-workflow.md). Every PR description ends with the agent-trail block (the template fills the skeleton); the human reviewer auto-rejects PRs where a session ID appears twice.

Do **not** approve your own work. Run the architect agent in a fresh Claude Code session before requesting human review.

## 9. Getting help

- Architecture questions → [`docs/architecture.md`](./docs/architecture.md)
- "Why did we do X this way?" → [`docs/decisions/`](./docs/decisions/)
- Sprint backlog / who owns what → [`docs/sprint-2.md`](./docs/sprint-2.md) (and `sprint-3.md` etc. when they appear)
- Everything else → ask on the team channel
