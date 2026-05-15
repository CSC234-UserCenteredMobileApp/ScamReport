# GEMINI.md — `apps/web`

Admin web portal. Vite + React 18 + TypeScript + Tailwind + shadcn/ui. SPA on Vercel. Auth-gated by Firebase Web SDK; calls existing Elysia API routes under `/admin/*` with `Authorization: Bearer <firebase-id-token>`.

## Layout

```
apps/web/src/
├── main.tsx                       # ReactDOM root
├── App.tsx                        # composes providers + router
├── styles/globals.css             # Tailwind directives + HSL CSS vars (light/dark)
├── app/
│   ├── providers.tsx              # QueryClient + Auth + Theme + i18n + Toaster
│   ├── router.tsx                 # createBrowserRouter route tree
│   └── theme-provider.tsx
├── routes/                        # one file per route
├── features/<feature>/
│   ├── api/                       # useQuery / useMutation hooks
│   ├── components/                # feature-scoped React components
│   ├── hooks/                     # feature-scoped hooks
│   └── pages/                     # composed page entries
├── components/                    # cross-feature widgets (app-shell, sidebar, topbar, ...)
│   └── ui/                        # shadcn-style primitives — DO NOT EDIT by hand for design tweaks; restyle via Tailwind/theme tokens
├── lib/
│   ├── auth/                      # firebase + auth-context + role-gate
│   ├── api/                       # client + validators + query-keys
│   └── i18n/                      # i18next init
└── i18n/{en,th}/<ns>.json         # translation tables
```

## Patterns

- **Feature-first**, mirrors `apps/mobile/lib/features/<feature>/{data,domain,presentation}`. On the web side: `api/`, `components/`, `hooks/`, `pages/`.
- **Contract reuse**. Import TypeBox schemas + types from `@my-product/shared`. Never handwrite a DTO.
- **Runtime validation**. Every response is checked by a precompiled TypeBox checker (`@/lib/api/validators.ts`). If a schema is missing for a new endpoint, **add it to `validators.ts` before calling `apiFetch`** — the compiler runs once at module load and stays cached.
- **Role gate.** `<ProtectedRoute role="admin">` reads `user.role` from `/auth/sync` (Postgres source of truth). Never trust a Firebase custom claim.
- **API client.** Use `apiFetch(path, validator, init)` from `@/lib/api/client.ts`. It auto-attaches a fresh ID token, handles 401/403, and validates the response shape. Don't call `fetch` directly outside this helper.
- **Toasts.** `sonner` is wired in `providers.tsx`. Use `toast.success/error(...)`.
- **Forms.** `react-hook-form` + `zod` resolver. See `features/moderation/components/action-dialog.tsx` for the canonical pattern.
- **Data tables.** TanStack Table v8 + shadcn `table.tsx` primitives. See `features/moderation/components/queue-table.tsx`.

## Theme

CSS variables in `src/styles/globals.css` mirror `apps/mobile/lib/core/theme/app_theme.dart`. **Never hardcode hex.** Reach for `bg-primary`, `text-foreground`, `bg-verdict-scam-bg`, etc.

Verdict palette tokens are bespoke (non-shadcn): `verdict.scam.{bg,fg}`, `verdict.suspicious.{bg,fg}`, `verdict.safe.{bg,fg}`, `verdict.unknown.{bg,fg}`. Available as Tailwind utilities (`bg-verdict-scam-bg`, `text-verdict-scam-fg`, ...) and as a `Badge` variant.

Fonts: Plus Jakarta Sans (Latin) + Sarabun (Thai fallback), loaded from Google Fonts in `index.html`.

## i18n

`react-i18next`, default locale `th`, fallback `en`. Three namespaces: `common`, `moderation`, `announcements`. Strings live in `src/i18n/<lang>/<ns>.json`.

**ARB ↔ JSON parity for v1 is manual.** When adding a new mobile string under `common`, mirror it here. ICU `{name}` placeholders convert to i18next `{{name}}`. Codegen later.

## Auth flow

1. `AuthProvider` (in `lib/auth/auth-context.tsx`) listens on `onAuthStateChanged`.
2. When a Firebase user is present, it calls `POST /auth/sync` (validated by `validators.authSync`) to fetch the canonical user from Postgres.
3. `ready` stays `false` until both Firebase hydration AND `/auth/sync` resolve. This prevents the role gate from flashing `/login` on cold reload.
4. `<ProtectedRoute>` reads `firebaseUser`, `role`, and `ready` from context.

## CORS

The admin portal calls `apps/api` from `http://localhost:5173` in dev and from the Vercel project domain in prod. CORS allowlist lives in `apps/api/src/index.ts` (`WEB_ORIGINS`). Preview deploys match a project-scoped regex (`scamreport-admin-*.vercel.app`), **not** wildcard `*.vercel.app`.

## Commands

| Command | What it does |
| --- | --- |
| `bun run --filter @my-product/web dev` | Vite dev server on `:5173` |
| `bun run --filter @my-product/web build` | Production build → `dist/` |
| `bun run --filter @my-product/web preview` | Preview the production build |
| `bun run --filter @my-product/web typecheck` | `tsc --noEmit` |
| `bun run --filter @my-product/web test` | `vitest run --coverage` |
| `bun run --filter @my-product/web lint` | ESLint flat config |
| `bun run dev:web` | Shorthand for the dev server (from repo root) |

## Deploy (Vercel)

- **Root Directory:** `apps/web`
- **Install Command:** `cd ../.. && bun install`
- **Build Command:** `bun run build`
- **Output Directory:** `dist`
- **Env vars:** `VITE_API_BASE_URL`, `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID`, `VITE_FIREBASE_APP_ID`. Never commit real values; `.env.example` documents the keys.

## Multi-agent workflow

Per `docs/ai-workflow.md`. Web PRs that touch `lib/auth/`, `lib/api/`, or the CORS allowlist on `apps/api/src/index.ts` MUST go through `security-reviewer` (auth + RBAC + CORS surface).
