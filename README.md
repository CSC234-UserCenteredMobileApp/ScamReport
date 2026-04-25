# ScamReport

ScamReport is a mobile product for reporting and tracking scam incidents, built on Flutter + Elysia.js with a shared TypeBox contract layer.

## Tech stack

| Layer | Tools |
| --- | --- |
| **Mobile** | Flutter 3.27, Riverpod, go_router, `drift` (SQLite), `shared_preferences`, `flutter_secure_storage`, Firebase (Auth, FCM, Analytics, Crashlytics) |
| **Backend** | Elysia.js on Bun, Prisma v7 with `@prisma/adapter-pg`, Supabase Postgres + Storage, Firebase Admin, Gemini API |
| **Contract** | TypeBox schemas in `packages/shared` — used as Elysia validators on the api side and as the source for Dart codegen on mobile |

## Repo layout

```
ScamReport/
├── apps/
│   ├── api/         Elysia.js backend (feature-first under src/features/)
│   └── mobile/      Flutter app (feature-first under lib/features/)
├── packages/
│   └── shared/      TypeBox schemas — the cross-app contract layer
├── docs/            Architecture + ADRs
└── scripts/         dev.sh, codegen.sh
```

## Quick start

```bash
# 1. Install workspace deps (root)
bun install

# 2. Generate Flutter platform folders (one-time per clone)
cd apps/mobile && flutter create . && cd ../..

# 3. Configure environment (see HOW_TO_CONTRIBUTE.md §3 for what each key means)
cp apps/api/.env.example apps/api/.env
# …edit .env with real Supabase / Firebase / Gemini values…

# 4. Generate the Prisma client
bun run prisma:generate

# 5. Place Firebase config files
#    Android: apps/mobile/android/app/google-services.json
#    iOS:     apps/mobile/ios/Runner/GoogleService-Info.plist
#    Backend: apps/api/firebase-service-account.json

# 6. Run dev (api + mobile concurrently)
bun run dev
```

## Documentation

- [`docs/architecture.md`](./docs/architecture.md) — how the three pieces fit together, contract-first workflow, testing strategy
- [`HOW_TO_CONTRIBUTE.md`](./HOW_TO_CONTRIBUTE.md) — first-run, where to add things, branch / PR conventions
- [`docs/decisions/`](./docs/decisions/) — Architecture Decision Records (ADRs)

## Working in a single app

Per-app `CLAUDE.md` files (and editor context) load best when you start in that app's directory:

```bash
cd apps/api && claude       # backend-only context
cd apps/mobile && claude    # mobile-only context
cd packages/shared && claude  # contract layer
```

## Contributing

We welcome contributions. Please read [`HOW_TO_CONTRIBUTE.md`](./HOW_TO_CONTRIBUTE.md) and our [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md), and use the pull request template that pre-fills when you open a PR.

Security issues — please follow [`SECURITY.md`](./SECURITY.md) (no public issues).

## License

[MIT](./LICENSE) © ScamReport Contributors
