# Rollback plan

> Cross-link from PRD §6.8 (Reliability). One page; expand as we learn from real incidents.

## When to roll back

Trigger a rollback when **any** of:

- Crash-free user rate drops below 99% within 1 hour of a release.
- A new feature ships and is reported broken by ≥ 2 users in `#scamreport-bugs` (or course Slack channel) within 24 hours.
- A security finding lands at `High` from `bun audit`, `gitleaks`, or the `security-reviewer` agent **on already-merged code** (i.e. it slipped past CI).
- A migration causes data corruption or makes a column unreadable.

## Procedure 1 — feature flag flip (preferred)

Every feature shipped in S2+ is wrapped in a Firebase Remote Config boolean flag (default-off in prod). To disable:

1. Open Firebase Console → Remote Config → `<project>`.
2. Find the flag key (e.g. `enable_biometric_login`, `enable_clipboard_scanner`).
3. Set the production value to `false`. Save + Publish.
4. Mobile clients pick up the change on the next `RemoteConfig.fetchAndActivate()` call (cold start, or on resume after the cache window).
5. Post in `#scamreport-incidents` (or course Slack) with: flag flipped, why, ETA on the fix, owner.

**No app redeploy required.** This is the rubric-aligned "rollback plan" mechanism. Confirmed dry-runnable; A.P should record one example flip in `docs/evidence/` before final demo.

## Procedure 2 — revert merge commit

For non-flag-gated work or when the flag itself is broken:

1. Identify the bad merge commit on `main`: `git log --merges -10`.
2. From a fresh `main`: `git revert -m 1 <merge-sha>`.
3. Open a hotfix PR titled `chore(revert): <original PR title>`. Skip the architect/qa loop only if the diff is purely a revert; otherwise loop normally.
4. Merge after CI green.
5. Force a flag flip (Procedure 1) if the affected feature is still callable client-side.

## Procedure 3 — Prisma migration revert

If the bad change is a Prisma migration:

1. Identify the offending migration directory: `apps/api/prisma/migrations/<timestamp>_<name>/`.
2. Write a **new** down-style migration that reverses the change (Prisma does not auto-generate a down). Land it via PR.
3. Apply with `bun --filter @my-product/api prisma migrate deploy`. Never edit applied migrations in place — that breaks every other dev's local state.
4. Confirm production schema matches the desired state with `bun --filter @my-product/api prisma migrate status`.
5. Re-run any data fixers required by the original change in reverse.

## Procedure 4 — Firestore rules / mirror revert

If a Firestore rules change breaks reads or a mirror writer leaks data:

1. `firebase deploy --only firestore:rules` from the **previous green commit's** `firestore.rules`.
2. If the bug is in the mirror writer (`apps/api/src/sync/firestore_sync.ts`), follow Procedure 2 (revert merge) and Procedure 1 (kill-switch the affected client read flag if any).

## On-call

Rotation is informal during the term-assignment window. The author of the most recent merge is on the hook for that day; if they're unreachable, A.P (orchestrator) takes the call. Document any off-hours incident in `docs/evidence/incidents/` with timeline, mitigation, and follow-up.

## Practice drill

A.P runs one full Procedure-1 dry-run before the final demo (2026-05-21):

1. Pick any non-critical flag.
2. Flip it on a staging Remote Config template.
3. Verify mobile picks up the change end-to-end on a Pixel 5 emulator.
4. Capture the timeline in `docs/evidence/rollback-drill.md`.

This satisfies the rubric's "rollback plan + evidence" requirement.
