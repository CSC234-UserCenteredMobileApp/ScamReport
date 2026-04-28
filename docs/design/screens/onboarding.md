# onboarding — First-launch tutorial

**PRD:** FR-10.1  **Roles:** any (first launch only)
**Flutter:** `apps/mobile/lib/features/onboarding/presentation/onboarding_screen.dart` (planned)

**Snapshot:** `../snapshots/user/onboarding.txt` · **Screenshot:** `../screenshots/user/onboarding.png`

## Purpose

Brief tutorial shown the first time the app opens. Explains the core "paste anything → check it" loop. Skippable.

## Layout

- Top bar: muted `Skip` link, right-aligned. Tap → dismiss flow, route to `home`.
- Hero illustration / icon (filled `Icons.shield_outlined` or similar in coral, large).
- Heading: `Check anything suspicious` (`textTheme.headlineSmall`, w700).
- Body: `Paste a phone number, link, or message. We compare against 2,184 verified scam reports.` (muted, `bodyMedium`).
- Page indicator (dots) under body — multi-step.
- Primary CTA: `Next` (full-width `FilledButton`).

The prototype only renders step 1 of the flow; copy for subsequent steps was not captured. The "Next" button advances; the final step's button should read `Get started` and route to `home`.

## States

- **First-launch only.** Persist a `seen_onboarding` flag on completion (or skip).
- No loading/error states.

## Interactions

- `Skip` → set flag, push-replace `home`.
- `Next` → advance step. On final step → set flag, push-replace `home`.

## Role variants

None. Only seen pre-auth or pre-account.

## Notes

- Copy for steps 2 / 3 was not captured. Likely covers: AI Search & report submission, then community/privacy promise. Confirm with the prototype when implementing.
- Per `design-review.md`: TH should be the default language (FR §6.4); the prototype defaults to EN.
