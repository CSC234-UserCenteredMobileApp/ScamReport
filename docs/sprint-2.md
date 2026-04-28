# Sprint 2 — Foundations (2026-04-30 → 2026-05-06)

> **Goal:** ship the foundational infrastructure (RBAC, CI gates, biometric, Verdict + Feed canonical screens) so Sprint 3 can build features on a stable base.
>
> **Demo:** mid-sprint check; full Sprint 2 review at start of Sprint 3 (2026-05-07).
>
> **How to use this board:** find a row with `_unclaimed_` in the **Owner** column, edit the cell to your name (`A.P` / `T.P` / `S.P` / `Y.R` / `B.S`), open a PR following the template, tick the test gate, mark the row as `done` in **Status** when merged. **Tests must pass before opening the PR** (team rule, 2026-04-28). Integration tests across feature boundaries are S.P's responsibility — feature authors hand off after their unit/widget tests pass.
>
> **Branch protection:** `main` is protected. Land changes via PR with at least one review + all CI gates green.

## Task board

| # | Task | Layer | Owner | Depends on | Test gate | Status |
|---|---|---|---|---|---|---|
| S2-01 | `requireRole('admin')` middleware + tests (`apps/api/src/core/middleware/require_role.ts`) | api | A.P | — | `bun --filter @my-product/api test` | done (PR #5) |
| S2-02 | `packages/shared/src/schemas/check.ts` (CheckRequest / CheckResponse) | shared | A.P | — | `bun run typecheck` | done (PR #5) |
| S2-03 | `apps/api/src/features/check/{check.route.ts,check.service.ts,check.repository.ts}` + route test | api | _unclaimed_ → recommend **T.P** | S2-01, S2-02 | `bun --filter @my-product/api test` covers route 200 + 4xx | pending |
| S2-04 | Mobile feature `apps/mobile/lib/features/verdict/` (P-13) — Clean-Arch canonical | mobile | _unclaimed_ → recommend **Y.R** | S2-02 | widget test for Scam / Suspicious / Safe / Unknown states | pending |
| S2-05 | Mobile feature `apps/mobile/lib/features/feed/` (P-03) — Postgres-read | mobile | _unclaimed_ → recommend **B.S** | none (mock repo allowed) | widget test for empty / loaded / filter states | pending |
| S2-06 | Mobile router redirect — `/mod` + `/admin/*` → `/login` if not admin (`apps/mobile/lib/core/router/app_router.dart`) | mobile | _unclaimed_ → recommend **Y.R** | none | router test asserting redirect for guest + non-admin user | pending |
| S2-07 | Biometric service `apps/mobile/lib/features/auth/data/biometric_service.dart` + Settings toggle (FR-1.6) | mobile | _unclaimed_ → recommend **B.S** | pubspec deps (in infra PR) | unit test for available / unavailable / fail / fallback paths | pending |
| S2-08 | CI coverage gate (≥ 80%) added to `.github/workflows/ci.yml` | infra | A.P | none | failing PR proof | done (PR `infra/s2-quality-gates`) |
| S2-09 | `.github/workflows/security.yml` — gitleaks + bun audit + dart analyze | infra | A.P | none | green CI run | done (PR `infra/s2-quality-gates`) |
| S2-10 | Crashlytics expansion in `apps/mobile/lib/main.dart` (FlutterError.onError + zone error handler + dev force-crash button) | mobile | _unclaimed_ → recommend **B.S** | pubspec deps (already present) | manual: trigger crash, see in Crashlytics dashboard | pending |
| S2-11 | Integration test scaffold `apps/mobile/integration_test/login_smoke_test.dart` — cold start → login → home | mobile + integration | _claimed by S.P_ | S2-04 + S2-05 (or stubs) | `flutter test integration_test/` passes on emulator | pending |
| S2-12 | Provision `evidence` Storage bucket in Supabase dashboard + verify with `getSignedUrl` smoke test | infra | A.P | none (out-of-repo console click) | manual smoke from `apps/api/src/core/supabase/storage.ts` | done (bucket created 2026-04-28; smoke test outstanding) |
| S2-13 | Enable Firestore in Firebase console + `firebase deploy --only firestore:rules` from infra PR's `firestore.rules` | infra | A.P | infra PR merged | rules visible in console; emulator test passes | done (deployed to `scamreport-62b4c` 2026-04-28) |
| S2-14 | Commit `.firebaserc` (project alias `scamreport-62b4c`) + Firestore offline persistence + Remote Config init in `apps/mobile/lib/core/di/firebase.dart` | infra + mobile | A.P | S2-13 | `dart analyze` clean; `flutter test` clean | done (PR `infra/s2-quality-gates`) |

## Sprint exit criteria

- [ ] All rows above marked `done`.
- [ ] CI green on `main` with coverage ≥ 80% on every package.
- [ ] No PR merged without the agent-trail block filled in.
- [ ] Sprint 3 backlog drafted at `docs/sprint-3.md` before 2026-05-07.

## Notes / decisions captured during the sprint

<!-- Append a one-liner here whenever the team makes a non-obvious call so
     the audit report can pull from a single timeline later. -->

- _2026-04-28_: A.P opens `infra/s2-prereqs` covering S2-01, S2-02, plus shared scaffolding (firestore.rules, firebase.json, CODEOWNERS, PR template, this board, pubspec deps, rollback plan stub). Other rows unblocked once that PR merges.
- _2026-04-28_: PRs #5 (infra prereqs), #6 (CODEOWNERS real handles) merged. Firestore enabled in `scamreport-62b4c`; rules deployed via `firebase deploy --only firestore:rules`. Supabase `evidence` bucket created. A.P opens `infra/s2-quality-gates` covering S2-08, S2-09, S2-14. Feature rows S2-03..S2-07, S2-10, S2-11 fully unblocked for teammates to claim.
