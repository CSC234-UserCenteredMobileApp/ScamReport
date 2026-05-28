# CLAUDE.md — ScamReport

Flutter app + Elysia.js backend (Bun) + shared TypeBox contract package. Schemas in `packages/shared`, imported by API as Elysia validators; mobile gets Dart types via codegen.

## Layout

- `apps/mobile/` — Flutter app (feature-first: `core/` + `features/<feature>/{data,domain,presentation}`)
- `apps/api/` — Elysia.js + Prisma backend
- `apps/web/` — admin web portal (Vite + React + Tailwind + shadcn/ui). Auth-gated SPA on Vercel, calls `/admin/*` + `/auth/sync`. See `apps/web/CLAUDE.md`.
- `packages/shared/` — TypeBox schemas shared across api, mobile, and web (contract layer)
- `scripts/` — `dev.sh` (runs api + mobile), `codegen.sh` (TypeBox → Dart)
- `docs/` — architecture + ADRs + per-screen design specs (`docs/design/index.md`)

## Working on a single app — read this

Start Claude **inside** app being edited so only its `CLAUDE.md` loads:

```bash
cd apps/api && claude
cd apps/mobile && claude
cd packages/shared && claude
```

Repo root loads this file only — fine for cross-cutting changes, wasteful for single-app work.

## Top-level commands (run from repo root)

| Command | Purpose |
| --- | --- |
| `bun install` | Install all workspace deps |
| `bun run dev` | Run api + mobile concurrently |
| `bun run test` | Run all tests across workspaces |
| `bun run typecheck` | Typecheck shared + api |
| `bun run lint` | Run `dart analyze` on mobile |
| `bun run prisma:generate` | Generate Prisma client |

## Details

Stack overview, contract-first workflow, testing strategy in [`docs/architecture.md`](./docs/architecture.md). Don't inline here.

## Design

Tokens in `apps/mobile/lib/core/theme/app_theme.dart` (warm coral primary, `VerdictPalette` extension). Per-screen specs in [`docs/design/`](./docs/design/index.md). For feature implementation, load `docs/design-review.md` (tokens + inventory) + relevant `docs/design/screens/<screen>.md` — do **not** open prototype HTML in `~/Documents/`; 1.4 MB per role, already distilled into spec docs.

## Multi-agent workflow

Four specialised Claude Code agents — `engineer`, `architect`, `qa`, `security-reviewer` — defined in [`.claude/agents/`](./.claude/agents/). AI that **writes** code may not **approve** it: engineer ships PR, fresh architect session reviews, qa extends tests + runs gates, security-reviewer audits PRs touching auth / RBAC / Firestore / secrets / validation. Human approver signs off last.

Full loop, per-agent rules, evidence-trail conventions in [`docs/ai-workflow.md`](./docs/ai-workflow.md). Plan-Mode discipline + team role split described there. Update both this section and `docs/ai-workflow.md` in same PR when workflow changes.

## Agent skills

### Issue tracker

GitHub issues at `CSC234-UserCenteredMobileApp/ScamReport` (via `gh` CLI). See [`docs/agents/issue-tracker.md`](./docs/agents/issue-tracker.md).

### Triage labels

Canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See [`docs/agents/triage-labels.md`](./docs/agents/triage-labels.md).

### Domain docs

Single-context — `CONTEXT.md` at repo root, ADRs at `docs/decisions/`. See [`docs/agents/domain.md`](./docs/agents/domain.md).
