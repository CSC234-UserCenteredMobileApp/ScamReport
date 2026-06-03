# Accessibility Checklist — ScamReport mobile

Referenced by [`.claude/agents/qa.md`](../.claude/agents/qa.md) §A11y audit.
Enforced automatically by `apps/mobile/test/a11y/a11y_sweep_test.dart`.
Last sweep: 2026-06-03 — 10/10 green.

## Automated gates (run on every `flutter test` / CI)

| Gate | Guideline | Standard |
|---|---|---|
| Tap target size | `androidTapTargetGuideline` (≥ 48×48 dp) | WCAG 2.5.8 / Material |
| Labeled tappables | `labeledTapTargetGuideline` | WCAG 4.1.2 |
| Text contrast | `textContrastGuideline` (≥ 4.5:1 normal text) | WCAG 1.4.3 AA |
| Dynamic type | renders at `textScaler: 2.0` without overflow | WCAG 1.4.4 |

Swept screens: check-input, login, lock screen, settings, home.
Adding a screen: append a `_ScreenCase` with its provider overrides.

## Findings fixed by the 2026-06-03 sweep

| Violation | Fix |
|---|---|
| White-on-coral `#F25F2A` = 3.26:1; coral text on bg = 3.12:1 | Light theme primary darkened to `#C8481B` (4.77:1 / 4.57:1). Dark theme keeps `#F25F2A` (5.55:1 on dark bg) with dark-ink `onPrimary` (5.2:1). Hardcoded `_brandPrimary` in button/nav themes parametrised. |
| "See all" buttons 121×40 (SectionHeader, `visualDensity.compact`) | `minimumSize: Size(48, 48)` |
| Login "Register" link bare `GestureDetector` 114×20 | Converted to `TextButton`, 48 dp min |
| Auth back arrow unlabeled | `tooltip: MaterialLocalizations.backButtonTooltip` |
| SectionHeader + home brand header overflow at 2.0× | Title/greeting wrapped in `Expanded` |
| PIN pad backspace/biometric keys unlabeled | `Semantics(button, label)` + l10n strings |

## Manual checks (per release, not automated)

- TalkBack pass over the 5 core flows (focus order is logical, no dead stops).
- Thai locale at 2.0× type on a physical device (Sarabun fallback metrics differ
  from the test environment's ambient font).
- Keyboard traversal on Flutter web build (Tab order + Enter activation).

## Known scope limits

- The sweep covers the 5 highest-traffic screens; admin/moderation surfaces are
  not yet swept (tracked in the test-backfill plan).
- Contrast guideline can't see images/gradients — image-over-text is reviewed
  in design review instead.
