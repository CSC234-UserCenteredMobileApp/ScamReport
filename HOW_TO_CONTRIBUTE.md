# How to contribute

Welcome. This guide gets you from a fresh clone to a running app and tells you where to add things.

## 1. Prerequisites

| Tool | Version | Install |
| --- | --- | --- |
| Bun | ≥ 1.1 | https://bun.sh |
| Flutter | ≥ 3.27 (stable) | https://docs.flutter.dev/get-started/install |
| PostgreSQL | ≥ 14 (local or hosted) | https://www.postgresql.org/download/ |
| Xcode / Android Studio | latest | for iOS / Android simulators |

## 2. First-run setup

```bash
# 1. Install workspace deps
bun install

# 2. Generate Flutter iOS/Android platform folders (one-time, per clone)
cd apps/mobile && flutter create . && cd ../..

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
- iOS: `apps/mobile/ios/Runner/GoogleService-Info.plist`

Mobile init runs from `apps/mobile/lib/core/di/firebase.dart`. If the config files aren't present, init logs a warning and returns false — the app still boots, just without Firebase features.

**Backend service account** (gitignored — place locally):
- Download from Firebase Console → Project Settings → Service accounts → "Generate new private key".
- Save as `apps/api/firebase-service-account.json` (matches the default `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env.example`).

**iOS push (FCM) — one-time manual setup:**
1. Apple Developer → Keys → create an APNs Auth Key (`.p8`).
2. Firebase Console → Project Settings → Cloud Messaging → upload the `.p8` with its Key ID and your Team ID.
3. In Xcode (after `flutter create .` runs), enable **Push Notifications** and **Background Modes → Remote notifications** capabilities on the Runner target.

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
| iOS simulator / macOS / Linux desktop | `flutter run` |
| Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` |
| Physical Android device | `flutter run --dart-define=API_BASE_URL=http://<LAN-ip>:3000` |

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
- Open a PR against `main`; one reviewer required
- PR description should name: what changed, why, and how you tested

### PR checklist

- [ ] `bun run typecheck` passes
- [ ] `bun run test` passes
- [ ] `bun run lint` passes (mobile changes)
- [ ] Shared schema changes committed alongside consumer changes in api + mobile
- [ ] No Firebase/env/service-account files committed

## 7. Testing expectations

- **api** — every route has at least one test under `apps/api/test/`
- **shared** — schemas should round-trip sample payloads; keep tests fast
- **mobile** — unit-test domain logic; widget-test `presentation/` for non-trivial widgets

## 8. Getting help

- Architecture questions → [`docs/architecture.md`](./docs/architecture.md)
- "Why did we do X this way?" → [`docs/decisions/`](./docs/decisions/)
- Everything else → ask on the team channel
