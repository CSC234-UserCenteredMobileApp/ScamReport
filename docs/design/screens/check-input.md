# check-input — Manual paste field

**PRD:** FR-2.1  **Roles:** all
**Flutter:** `apps/mobile/lib/features/check/presentation/check_input_screen.dart` (planned)

**Snapshot:** `../snapshots/user/check-input.txt` · **Screenshot:** `../screenshots/user/check-input.png`

## Purpose

Alternative entry to verdict for users who didn't have a clipboard banner. Multi-line paste field + privacy reassurance.

## Layout

- Top bar: title `Check something` + back arrow.
- Multi-line input: full-width text area, placeholder `Paste or type a phone number, link, or message`.
- Privacy note: `We never store what you check unless you choose to report it.` (muted `bodySmall`).
- Primary CTA: `Run check` (full-width `FilledButton`, disabled when input is empty).
- Sample chips below CTA: `Try a number`, `Try a link` — tapping pre-fills input with sample data.
- No bottom nav (this is a flow-only screen; per source `noNav.includes('check-input')`).

## States

- **Idle / empty** — CTA disabled.
- **Filled** — CTA enabled.
- **Submitted** — transitions to `verdict` (which shows a "Checking…" loader for ~1.5s then result).

## Interactions

- Tap `Run check` → `runCheck(input)` → push `verdict` with payload `{ query, verdict }`.
- Tap sample chip → fill input, focus retained.
- Back arrow → pop to caller (`home` typically).

## Role variants

None — every role uses the same screen.

## Notes

- The full-bleed (no bottom nav) layout matches `verdict` and `login`; treat these as "flow" screens.
- Hashing-on-device claim (per `verdict` loader copy) is just illustrative — the actual verdict resolution path is server-side (FR-2.2). Keep the privacy copy on this screen.
