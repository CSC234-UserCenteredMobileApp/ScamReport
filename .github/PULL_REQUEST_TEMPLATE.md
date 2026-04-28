## Summary

<!-- 1-3 bullets describing what changed and why. Focus on the *why*. -->

## Linked plan / sprint task

<!-- Link to the row in docs/sprint-<N>.md or the plan section in
     ~/.claude/plans/task-scaffold-flutter-greedy-curry.md that this PR
     delivers. Every PR must trace back to an approved plan. -->

## Test plan

- [ ] `bun run typecheck` passes
- [ ] `bun --filter @my-product/api test` passes _(if api was touched)_
- [ ] `cd apps/mobile && dart analyze && flutter test` passes _(if mobile was touched)_
- [ ] Tests written **before** opening this PR (team rule, 2026-04-28)
- [ ] Manually exercised the affected flow on at least one platform
- [ ] Coverage did not drop below 80% line per package

## Docs touched (per W2 sync map in plan)

<!-- Tick every doc that should change in this PR. If unticked, justify in
     the Notes section why the doc stays out of sync. -->
- [ ] `PRODUCT-REQUIREMENTS.md`
- [ ] `DATABASE_DESIGN.md`
- [ ] `docs/architecture.md`
- [ ] `SECURITY.md`
- [ ] `README.md`
- [ ] `GEMINI.md` (or per-app `GEMINI.md` / `CLAUDE.md`)
- [ ] `docs/design/` per-screen specs
- [ ] None — see "Notes for reviewer" for why

## Notes for reviewer

<!-- Anything tricky, alternatives considered, follow-up tasks, screenshots. -->

---

## AI agent trail (rubric: writer ≠ approver)

Fill in a session ID for every agent that touched this PR. Same session ID
appearing twice = auto-rejected by the human reviewer (rubric violation).
Use `n/a` only when an agent type genuinely did not run on this PR
(e.g. security-reviewer is `n/a` when the diff has no security surface).

- **Author agent:** engineer · session `_______`
- **Architect agent:** architect · session `_______`
- **QA agent:** qa · session `_______`
- **Security agent:** security-reviewer · session `_______` (or `n/a`)
- **Human approver:** `_______`

### What this AI did

<!-- Required by the rubric: a short, human-authored description (3-6 lines)
     explaining what the agents produced and why this PR's author is
     accountable for every line. Do NOT let an agent write this section. -->
